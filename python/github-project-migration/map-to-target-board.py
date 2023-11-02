import json
import os
import sys

# This function maps statuses on your source board to those on your
# target board.
def map_old_status_to_new(old_status):
    if "Backlog" in old_status:
        return "Product planning"
    if "Ready To Start" in old_status:
        return "Ready to develop"
    if "In Progress" in old_status:
        return "In development"
    if "Done" in old_status:
        return None
    if "Parked" in old_status:
        return None

# Read the issues data from file.
with open('issues.json') as f:
	issues = json.loads(f.read())

# Iterate over each of the issues, and map the old status to their
# new status.
for issue in issues:
    try:
        number = issue["content"]["number"]
        old_status = issue["fieldValueByName"]["name"]
        new_status = map_old_status_to_new(old_status)
        if new_status is None:
            print(
                "ignoring issue {} because its status is {}".format(
                    number,
                    old_status
                ),
                file=sys.stderr
            )
            continue
		# Output some new JSON representing the issue and its mapped status.
        mapped_issue = {
            "number": number,
            "id": issue["content"]["id"],
            "old_status": old_status,
            "new_status": new_status
        }
        print(json.dumps(mapped_issue))
    except Exception as e:
        print(
            "error processing issue. error: {}, issue: {}".format(e, issue),
            file=sys.stderr
        )
        