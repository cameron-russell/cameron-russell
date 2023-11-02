#!/bin/bash

set -eu -o pipefail

project_id=$(gh api graphql --jq '.data.organization.projectV2.id' -f query='
  query{
	organization(login:"sky-uk"){
	  projectV2(number:448){
	    id
	  }
	}
  }')

function addToProject {
    local issue_id="$1"

    gh api graphql --silent -f query="
    mutation {
      addProjectV2ItemById(
        input: {contentId: \"$issue_id\", projectId: \"$project_id\"}
      ) {
        item {
          id
        }
      }
    }
  "
}

function deleteFromProject {
    local issue_id="$1"

    gh api graphql -f query="
    mutation {
      deleteProjectV2Item(
        input: {itemId: \"$issue_id\", projectId: \"$project_id\"}
      ) {
        deletedItemId
      }
    }
  " >> deleted
}


 while read -r line; do
    curId=$(echo "$line" | jq ".id" | sed 's/"//g')
    curIssueId=$(echo "$line" | jq ".content.id" | sed 's/"//g')
    # addToProject "$curIssueId"
    deleteFromProject "$curId"
 done < <(jq -c ".[]" "issues.json")
