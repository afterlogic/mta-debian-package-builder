# copy Spamassassin-tagged email to Spam folder
require ["fileinto", "envelope", "imap4flags"];

if header :contains "X-Spam-Flag" "YES" {
    fileinto "Spam";
    stop;
}
