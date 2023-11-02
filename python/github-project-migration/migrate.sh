#!/bin/bash

# This script assumes that:

#     The output from the Python script to map statuses has been saved in $issue_statuses.
#     The status options have been saved in $status_option_ids.
#     The ID of the project has been saved in $project_id.

set -eu -o pipefail

project_id=$(gh api graphql --jq '.data.organization.projectV2.id' -f query='
  query{
	organization(login:"sky-uk"){
	  projectV2(number:448){
	    id
	  }
	}
  }')

status_option_ids=$(gh api graphql --jq ".data.organization.projectV2.field.options.[]"  -f query='
  query{
	organization(login: "sky-uk"){
	  projectV2(number: 448) {
	    field(name:"Status"){
	      __typename
	      ... on ProjectV2SingleSelectField{
 		    id
		    options{
		      id
		      name
		    }
	      }
	    }
	  }
	}
  }')

echo -n "$issue_statuses" | while read -r issue; do
	# Parse each JSON object into the variables we need.
	issue_id=$(echo -n "$issue" | jq '.id' | sed 's/"//g')
	issue_number=$(echo -n "$issue" | jq '.number')
	new_status=$(echo -n "$issue" | jq '.new_status' | sed 's/"//g')
	status_option_id=$(echo -n "$status_option_ids" | jq ".[] | select(.name == \"$new_status\").id" | sed 's/"//g')

	# Print out the variables we're using for the user to see.
	echo "issue id: $issue_id"
	echo "issue number: $issue_number"
	echo "new status: $new_status"
	echo "status option id: $status_option_id"

	# Check that we've got valid data.
	if [[ -z "$issue_id" || -z "$issue_number" || -z "$new_status" || -z "$status_option_id" ]]; then
		echo "invalid args"
		exit 1
	fi

	echo "adding issue number $issue_number to new board"

	# First, add the issue to the new project, and store the item/card ID in a variable.
	item_id=$(gh api graphql -f query='
		mutation{
			addProjectV2ItemById(input:{
				contentId:"'"$issue_id"'",
				projectId:"'"$project_id"'"
			}){
				item{
					id
					project{
						title
					}
				}
			}
		}' | jq '.data.addProjectV2ItemById.item.id' | sed 's/"//g')

	echo "moving issue number $issue_number to new status $new_status"

	# Then, assign the correct status to the new project item/card.
	gh api graphql --jq '.data.updateProjectV2ItemFieldValue.projectV2Item.fieldValueByName.name' -f query='
		mutation{
			updateProjectV2ItemFieldValue(input:{
				itemId:"'"$item_id"'",
				value:{singleSelectOptionId:"'"$status_option_id"'"},
				fieldId:"'"$status_field_id"'",
				projectId:"'"$project_id"'",
				clientMutationId:"status-update"
			}){
				projectV2Item{
					fieldValueByName(name: "Status"){
						__typename
						... on ProjectV2ItemFieldSingleSelectValue{
							name
						}
					}
				}
			}
		}'
done
