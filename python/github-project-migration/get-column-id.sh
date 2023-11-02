#!/bin/bash

gh api graphql --jq ".data.organization.projectV2.field.options.[] | select(.name == \"📋 Backlog\").id"  -f query='
  query{
	organization(login: "sky-uk"){
	  projectV2(number: 492) {
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
  }'