#!/bin/bash

# Function to create certificates and related resources
create_certificates() {
    echo "Enter the Domain Names (space-separated):"
    read DOMAIN_NAMES

    # Split the input into an array of domain names
    IFS=" " read -ra DOMAIN_NAME_ARRAY <<< "$DOMAIN_NAMES"

    # Loop through each domain name and create certificates
    for DOMAIN_NAME in "${DOMAIN_NAME_ARRAY[@]}"; do
        # Create the DNS zone name by replacing '.' with '-'
        DNS_ZONE_NAME=$(echo "$DOMAIN_NAME" | sed 's/\./-/g')

        # Variables for the certificate and DNS zone
        CERTIFICATE_NAME="$DNS_ZONE_NAME-cert"
        CERTIFICATE_MAP_NAME="$DNS_ZONE_NAME-cert-map"
        CERTIFICATE_MAP_ENTRY_NAME="$DNS_ZONE_NAME-cert-map-entry"
        
        # Set the authorization name to authorize your domain
        AUTHORIZATION_NAME="$DNS_ZONE_NAME-auth"

        # Create DNS authorization
        echo "Creating DNS authorization for $DOMAIN_NAME..."
        gcloud certificate-manager dns-authorizations create "$AUTHORIZATION_NAME" --domain="$DOMAIN_NAME"

        # Create a Google-managed certificate referencing the DNS authorization
        echo "Creating certificate for $DOMAIN_NAME..."
        gcloud certificate-manager certificates create "$CERTIFICATE_NAME" --domains="*.$DOMAIN_NAME,$DOMAIN_NAME" --dns-authorizations="$AUTHORIZATION_NAME"

        # Create a certificate map
        echo "Creating certificate map for $DOMAIN_NAME..."
        gcloud certificate-manager maps create "$CERTIFICATE_MAP_NAME"

        # Create certificate map entries
        echo "Creating certificate map entries for $DOMAIN_NAME..."
        gcloud certificate-manager maps entries create "${CERTIFICATE_MAP_ENTRY_NAME}1" --map="$CERTIFICATE_MAP_NAME" --certificates="$CERTIFICATE_NAME" --hostname="*.$DOMAIN_NAME"
        gcloud certificate-manager maps entries create "${CERTIFICATE_MAP_ENTRY_NAME}2" --map="$CERTIFICATE_MAP_NAME" --certificates="$CERTIFICATE_NAME" --hostname="$DOMAIN_NAME"
        
        # Optionally, describe the DNS authorization for confirmation
        gcloud certificate-manager dns-authorizations describe "$AUTHORIZATION_NAME"
    done
    echo "Certificate creation process completed."
}

# Function to delete certificates and related resources
delete_certificates() {
    echo "Enter the Domain Names (space-separated):"
    read DOMAIN_NAMES

    # Split the input into an array of domain names
    IFS=" " read -ra DOMAIN_NAME_ARRAY <<< "$DOMAIN_NAMES"

    # Loop through each domain name and delete certificates
    for DOMAIN_NAME in "${DOMAIN_NAME_ARRAY[@]}"; do
        # Create the DNS zone name by replacing '.' with '-'
        DNS_ZONE_NAME=$(echo "$DOMAIN_NAME" | sed 's/\./-/g')

        # Variables for the certificate and DNS zone
        CERTIFICATE_NAME="$DNS_ZONE_NAME-cert"
        CERTIFICATE_MAP_NAME="$DNS_ZONE_NAME-cert-map"
        CERTIFICATE_MAP_ENTRY_NAME="$DNS_ZONE_NAME-cert-map-entry"
        AUTHORIZATION_NAME="$DNS_ZONE_NAME-auth"

        # Delete certificate map entries
        echo "Deleting certificate map entries for $DOMAIN_NAME..."
        if gcloud certificate-manager maps entries describe "${CERTIFICATE_MAP_ENTRY_NAME}1" --map="$CERTIFICATE_MAP_NAME" --quiet &>/dev/null; then
            gcloud certificate-manager maps entries delete "${CERTIFICATE_MAP_ENTRY_NAME}1" --map="$CERTIFICATE_MAP_NAME" --quiet
            echo "Deleted certificate map entry 1 for $DOMAIN_NAME"
        fi
        if gcloud certificate-manager maps entries describe "${CERTIFICATE_MAP_ENTRY_NAME}2" --map="$CERTIFICATE_MAP_NAME" --quiet &>/dev/null; then
            gcloud certificate-manager maps entries delete "${CERTIFICATE_MAP_ENTRY_NAME}2" --map="$CERTIFICATE_MAP_NAME" --quiet
            echo "Deleted certificate map entry 2 for $DOMAIN_NAME"
        fi

        # Delete the certificate map
        echo "Deleting certificate map for $DOMAIN_NAME..."
        if gcloud certificate-manager maps describe "$CERTIFICATE_MAP_NAME" --quiet &>/dev/null; then
            gcloud certificate-manager maps delete "$CERTIFICATE_MAP_NAME" --quiet
            echo "Deleted certificate map for $DOMAIN_NAME"
        fi

        # Delete the certificate
        echo "Deleting certificate $CERTIFICATE_NAME..."
        if gcloud certificate-manager certificates describe "$CERTIFICATE_NAME" --quiet &>/dev/null; then
            gcloud certificate-manager certificates delete "$CERTIFICATE_NAME" --quiet
            echo "Deleted certificate $CERTIFICATE_NAME"
        fi

        # Delete the DNS authorization
        echo "Deleting DNS authorization $AUTHORIZATION_NAME..."
        if gcloud certificate-manager dns-authorizations describe "$AUTHORIZATION_NAME" --quiet &>/dev/null; then
            gcloud certificate-manager dns-authorizations delete "$AUTHORIZATION_NAME" --quiet
            echo "Deleted DNS authorization $AUTHORIZATION_NAME"
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
