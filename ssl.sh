#!/bin/bash

# Function to create certificates and related resources
create_certificates() {
    echo "Enter the Domain Names (space-separated):"
    read DOMAIN_NAMES

    # Split the input into an array of domain names
    IFS=" " read -ra DOMAIN_NAME_ARRAY <<< "$DOMAIN_NAMES"

    # Loop through each domain name and create certificates
    for DOMAIN_NAME in "${DOMAIN_NAME_ARRAY[@]}"; do
        DNS_ZONE_NAME=$(echo "$DOMAIN_NAME" | sed 's/\./-/g')

        CERTIFICATE_NAME="$DNS_ZONE_NAME-cert"
        CERTIFICATE_MAP_NAME="$DNS_ZONE_NAME-cert-map"
        CERTIFICATE_MAP_ENTRY_NAME="$DNS_ZONE_NAME-cert-map-entry"
        AUTHORIZATION_NAME="$DNS_ZONE_NAME-auth"

        echo "Creating DNS authorization for $DOMAIN_NAME..."
        gcloud certificate-manager dns-authorizations create "$AUTHORIZATION_NAME" --domain="$DOMAIN_NAME"

        echo "Creating certificate for $DOMAIN_NAME..."
        gcloud certificate-manager certificates create "$CERTIFICATE_NAME" --domains="*.$DOMAIN_NAME,$DOMAIN_NAME" --dns-authorizations="$AUTHORIZATION_NAME"

        echo "Creating certificate map for $DOMAIN_NAME..."
        gcloud certificate-manager maps create "$CERTIFICATE_MAP_NAME"

        echo "Creating certificate map entries for $DOMAIN_NAME..."
        gcloud certificate-manager maps entries create "${CERTIFICATE_MAP_ENTRY_NAME}1" --map="$CERTIFICATE_MAP_NAME" --certificates="$CERTIFICATE_NAME" --hostname="*.$DOMAIN_NAME"
        gcloud certificate-manager maps entries create "${CERTIFICATE_MAP_ENTRY_NAME}2" --map="$CERTIFICATE_MAP_NAME" --certificates="$CERTIFICATE_NAME" --hostname="$DOMAIN_NAME"

        gcloud certificate-manager dns-authorizations describe "$AUTHORIZATION_NAME"
    done
    echo "Certificate creation process completed."
}

# Function to delete certificates and related resources
delete_certificates() {
    echo "Enter the Domain Names (space-separated):"
    read DOMAIN_NAMES

    IFS=" " read -ra DOMAIN_NAME_ARRAY <<< "$DOMAIN_NAMES"

    for DOMAIN_NAME in "${DOMAIN_NAME_ARRAY[@]}"; do
        DNS_ZONE_NAME=$(echo "$DOMAIN_NAME" | sed 's/\./-/g')

        CERTIFICATE_NAME="$DNS_ZONE_NAME-cert"
        CERTIFICATE_MAP_NAME="$DNS_ZONE_NAME-cert-map"
        AUTHORIZATION_NAME="$DNS_ZONE_NAME-auth"

        echo "Fetching certificate map entries for $DOMAIN_NAME..."
        MAP_ENTRIES=$(gcloud certificate-manager maps entries list --map="$CERTIFICATE_MAP_NAME" --format="value(NAME)")

        if [ -n "$MAP_ENTRIES" ]; then
            for ENTRY in $MAP_ENTRIES; do
                echo "Deleting certificate map entry: $ENTRY..."
                gcloud certificate-manager maps entries delete "$ENTRY" --map="$CERTIFICATE_MAP_NAME" --quiet
            done
        fi

        echo "Deleting certificate map for $DOMAIN_NAME..."
        if gcloud certificate-manager maps describe "$CERTIFICATE_MAP_NAME" --quiet &>/dev/null; then
            gcloud certificate-manager maps delete "$CERTIFICATE_MAP_NAME" --quiet
        fi

        echo "Deleting certificate $CERTIFICATE_NAME..."
        if gcloud certificate-manager certificates describe "$CERTIFICATE_NAME" --quiet &>/dev/null; then
            gcloud certificate-manager certificates delete "$CERTIFICATE_NAME" --quiet
        fi

        echo "Deleting DNS authorization $AUTHORIZATION_NAME..."
        if gcloud certificate-manager dns-authorizations describe "$AUTHORIZATION_NAME" --quiet &>/dev/null; then
            gcloud certificate-manager dns-authorizations delete "$AUTHORIZATION_NAME" --quiet
        fi
    done
    echo "Certificate deletion process completed."
}

# Main script logic
echo "Choose an action:"
echo "1) Create Certificates"
echo "2) Delete Certificates"
read -p "Enter your choice (1 or 2): " choice

if [ "$choice" -eq 1 ]; then
    create_certificates
elif [ "$choice" -eq 2 ]; then
    delete_certificates
else
    echo "Invalid choice. Please enter 1 or 2."
fi
