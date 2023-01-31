#!/bin/bash
# NameSileCertbot-DNS-01 0.2.2
## https://stackoverflow.com/questions/59895
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE"  ]; do
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /*  ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"
echo "Received request for" "${CERTBOT_DOMAIN}"
cd ${DIR}
source config.sh

#DOMAIN=`echo $CERTBOT_DOMAIN | awk '{ split($0, a, "."); l = length(a); if (l > 2) { print(a[l-1] "." a[l]); } else { print($0); } }'`
DOMAIN=`echo $CERTBOT_DOMAIN | awk -F. '{ if (NF > 2) { ii = 3; for (i=ii; i<NF; i++) printf("%s.", $i); printf("%s",$NF); } else { print($0); }}'`
VALIDATION=${CERTBOT_VALIDATION}
RRHOST=`echo $CERTBOT_DOMAIN | awk -F. '{ if (NF > 2) { ii = 1; for (i=ii; i<NF-2; i++) printf(".%s", $i); printf(".%s",$(NF-2)); }}'`
VALKEYFULL="_acme-challenge$RRHOST.$DOMAIN"
VALKEY="_acme-challenge$RRHOST"

## Get the XML & record ID
curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > $CACHE$DOMAIN.xml

## Check for existing ACME record
if grep -q "$VALKEYFULL" $CACHE$DOMAIN.xml
then

	## Get record ID
	RECORD_ID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '$VALKEYFULL' ]" $CACHE$DOMAIN.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`
	## Update DNS record in Namesilo:
	curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$RECORD_ID&rrhost=$VALKEY&rrvalue=$VALIDATION&rrttl=3600" > $RESPONSE
	RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()"  $RESPONSE`

	## Process response, maybe wait
	case $RESPONSE_CODE in
		300)
			echo "Update success. Please wait 15 minutes for validation..."
			# Records are published every 15 minutes. Wait for 16 minutes, and then proceed.
			for (( i=0; i<16; i++ )); do
				echo "Minute" ${i}
				sleep 60s
			done
			;;
		280)
			RESPONSE_DETAIL=`xmllint --xpath "//namesilo/reply/detail/text()"  $RESPONSE`
			echo "Update aborted, please check your NameSilo account."
			echo "Domain: $DOMAIN"
			echo "rrid: $RECORD_ID"
			echo "reason: $RESPONSE_DETAIL"
			;;
		*)
			echo "Namesilo returned code: $RESPONSE_CODE"
			echo "Reason: $RESPONSE_DETAIL"
			echo "Domain: $DOMAIN"
			echo "rrid: $RECORD_ID"
			;;
	esac

else

	## Add the record
	curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrtype=TXT&rrhost=$VALKEY&rrvalue=$VALIDATION&rrttl=3600" > $RESPONSE
	RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()"  $RESPONSE`

	## Process response, maybe wait
	case $RESPONSE_CODE in
		300)
			echo "Addition success. Please wait 15 minutes for validation..."
			# Records are published every 15 minutes. Wait for 16 minutes, and then proceed.
			for (( i=0; i<16; i++ )); do
				echo "Minute" ${i}
				sleep 60s
			done
			;;
		280)
			RESPONSE_DETAIL=`xmllint --xpath "//namesilo/reply/detail/text()"  $RESPONSE`
			echo "DNS addition aborted, please check your NameSilo account."
			echo "Domain: $DOMAIN"
			echo "rrid: $RECORD_ID"
			echo "reason: $RESPONSE_DETAIL"
			;;
		*)
			RESPONSE_DETAIL=`xmllint --xpath "//namesilo/reply/detail/text()"  $RESPONSE`
			echo "Namesilo returned code: $RESPONSE_CODE"
			echo "Reason: $RESPONSE_DETAIL"
			echo "Domain: $DOMAIN"
			echo "rrid: $RECORD_ID"
			;;
	esac

fi
