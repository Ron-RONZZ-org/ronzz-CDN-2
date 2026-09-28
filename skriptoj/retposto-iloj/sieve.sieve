require ["fileinto", "copy", "variables"];

# -----------------------------------------------------------------
# CONFIGURABLE FOLDER NAMES
# -----------------------------------------------------------------
# Set the actual name of your trash/deleted folder
set "TRASH_FOLDER" "Trash";   # Change to "Deleted Items", "INBOX.Trash", etc.

# (Optional) Set other folder names if they differ
set "NOTIF_FOLDER" "notifications";
set "UNI_FOLDER"   "uni_stuff";

# -----------------------------------------------------------------
# RULE 1: Subject contains finance/invoice keywords
# -----------------------------------------------------------------
if header :contains "Subject" ["reçu", "receipt", "facture", "bill"] {
    # Forward a copy to finance department
    redirect "finance@ronzz.org";
    # Move the original message to the trash folder
    fileinto "${TRASH_FOLDER}";
    # Stop processing to avoid further actions (including inbox delivery)
    stop;
}

# -----------------------------------------------------------------
# RULE 2: Automatic / no-reply senders
# -----------------------------------------------------------------
if header :contains "From" ["noreply", "ne-pas-repondre", "notification", "donotreply"] {
    fileinto "${NOTIF_FOLDER}";
    stop;
}

# -----------------------------------------------------------------
# RULE 3: University or .edu senders
# -----------------------------------------------------------------
elsif anyof (
    header :matches "From" "*@*univ",
    header :matches "From" "*@*.edu"
) {
    fileinto "${UNI_FOLDER}";
    stop;
}
