#!/bin/bash

gh api graphql \
    --paginate \
    --jq '.data.organization.projectV2.items.nodes[]' \
    -f query='
query($endCursor: String) {
  organization(login:"sky-uk"){
    projectV2(number:448){
      items(first:10, after: $endCursor){
        pageInfo{ hasNextPage endCursor }
        nodes{
          id
          fieldValueByName(name:"Status"){
            __typename
            ... on ProjectV2ItemFieldSingleSelectValue{
              name
            }
          }
          content{
            __typename
            ... on Issue{
              number
              title
              id
            }
          }
        }
      }
    }
  }
}' | jq "select(.fieldValueByName.name == \"📋 Backlog\")" | sed 's/^}$/},/g' | sed '1s/^{$/[{/g' | sed '$s/^},$/}]/g' > issues.json

