#!/opt/homebrew/bin/bash

#function sendCancel {
#  local subId="$1"
#  local product="$2"
#
#  curl --location 'https://ott-ppg-prod-external.prod.ce.us-west-2-aws.skooniedc.com/partners-purchases-gateway/v1/internal/notifications' \
#  --header "X-SkyInt-RequestID: $(genuuid)" \
#  --header 'Content-Type: application/json' \
#  --header 'Accept: application/json' \
#  --header 'X-SkyOTT-Provider: NBCU' \
#  --header 'X-SkyOTT-Territory: US' \
#  --header 'X-SkyOTT-Proposition: NBCUOTT' \
#  --header 'x-skyott-partnerid: DIRECTV-US' \
#  --header 'Authorization: Basic xxxxx' \
#  --data "{
#       \"partnerSubscription\":{
#          \"partnerSubscriptionId\":\"$subId\",
#          \"productId\":{
#             \"type\":\"PartnerProductId\",
#             \"value\":\"$product\"
#          },
#          \"partnerSubscriptionLineId\":\"$product\"
#       },
#       \"type\":\"Cancel\"
#    }"
#}
#
#function sendPurchase {
#  local subId="$1"
#  local product="$2"
#  local householdId="$3"
#  local transaction="$4"
#
#  curl --location 'https://ott-ppg-prod-external.prod.ce.us-west-2-aws.skooniedc.com/partners-purchases-gateway/v1/internal/notifications' \
#  --header 'x-skyott-territory: US' \
#  --header 'x-skyott-proposition: NBCUOTT' \
#  --header 'x-skyott-provider: NBCU' \
#  --header "x-skyint-requestid: $(genuuid)" \
#  --header 'x-skyott-partnerid: DIRECTV-US' \
#  --header 'Content-Type: application/json' \
#  --header 'Authorization: Basic xxxxx' \
#  --data "{
#      \"type\": \"Purchase\",
#      \"partnerSubscription\": {
#          \"partnerSubscriptionId\": \"$subId\",
#          \"productId\": {
#              \"type\": \"PartnerProductId\",
#              \"value\": \"$product\"
#          },
#          \"partnerSubscriptionLineId\": \"$product\",
#      },
#      \"householdId\": \"$householdId\",
#      \"transaction\": \"$transaction\"
#  }"
#}


# for each line
while read -r line;do
  old_subId=$(echo "$line" | cut -d',' -f1)
  householdId=$(echo "$line" | cut -d',' -f6)
  # shellcheck disable=SC2001
  json=$(echo "$line" | sed -e 's/^[^{]*//g')
  consumer_identity=$(echo "$json" | jq ".consumer_identity" | tr -d '"')
  old_product=$(echo "$json" | jq ".product" | tr -d '"')

# send cancel for the partnersusbcriptionid for the current record
#  echo "cancelling $subId"
#  sendCancel "$old_subId" "$old_product"

# find the new information from CSV sent by boku by cross-referencing the consumer_identity
  mapfile -t boku_subs < <(grep "$consumer_identity" ~/Downloads/DTVUS\ Peacock.csv)
  count=${#boku_subs[@]}

  if (( count > 0 ));then
    # for each new subscription
    for item in "${boku_subs[@]}"
    do
    # create transaction
      new_product=$(echo "$item" | cut -d',' -f12 | tr -d '"')
      new_bundle_id=$(echo "$item" | cut -d',' -f4 | tr -d '"')
      new_transaction=$(echo "$json" | jq -c ".bundle_id=\"$new_bundle_id\" | .product=\"$new_product\"")
      sig=$(grep "$old_subId" "$HOME/Desktop/removemebundlechecks.txt" | cut -d',' -f13 | cut -d':' -f2)
      new_transaction_with_sig="$(echo "$new_transaction" | base64):$sig"
    # send purchase
#      sendPurchase "$new_bundle_id" "$new_product" "$householdId" "$new_transaction_with_sig"
    # if it's cancelled in boku spreadsheet, send cancel
      echo "$new_transaction_with_sig"
      if echo "$item" | grep "\"cancelled\"" > /dev/null 2>&1;then
          echo "this record was cancelled"
#        sendCancel "$new_bundle_id" "$new_product"
      fi
    done
  else
    echo "Couldn't find link for consumer_identity: $consumer_identity"
  fi
done < <(sed '2q;d' ~/Desktop/removemebundlechecks_formatted.txt)
