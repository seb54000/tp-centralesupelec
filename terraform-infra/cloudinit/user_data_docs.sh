#! /bin/bash -xe
# https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
BEGIN_DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "BEGIN_DATE : $BEGIN_DATE"

# echo "### Set new hostname ###"
# sudo hostnamectl set-hostname "${hostname_new}"

# echo "### Add passwd, create user, finalize xrdp config ###"
# sudo useradd -m -s /bin/bash cloudus
# echo "cloudus:${cloudus_user_passwd}" | sudo chpasswd
# Nice way to avoid cloudus ask for password when doing sudo (so relax for testing env)
# echo "cloudus ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/cloudus')

echo "Allow PasswordAuthentication for SSH - for easier use"
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

# # For the following to work, we need either an AWS AMI that already has the aws CLI or isntal it
# # And of course we also need specific configuration for this VM with Assume role to call the API
# # We cannot do this simply in the cloudinit write_file directive as we need substitution with the correct AZ that we won't have in the cloudinit of course
    # Maybe do it through write_file for the skeletton and just a sed in this script (or a second script post cloudinit) to only change the AZ
        # https://stackoverflow.com/questions/34095839/cloud-init-what-is-the-execution-order-of-cloud-config-directives
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/)

cat <<EOF > /var/tmp/index.php
<?php
    \$output = shell_exec('aws ec2 describe-instances --region $${AZ::-1} --output text --filters Name=instance-state-name,Values=running --query "Reservations[].Instances[].[InstanceId,PublicIpAddress,Tags[?Key==\'Name\']|[0].Value,Tags[?Key==\'AUTO_DNS_NAME\']|[0].Value]" 2>&1');
    echo "<h1><pre>\n\$output</pre></h1>";
?>
EOF
sudo mv /var/tmp/index.php /var/www/html/index.php


# Download a list of files (pdf for the TP)
pip install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib
python3 /var/tmp/gdrive.py
rm -f /var/tmp/token.json


# TODO forge a simple HTML file with a list of students to display who is using what VM/username for AWS API calls and VM usage
# Sebastien CLAUDE | vm00 | user00 | AK=************ | IP adress of the VM ....





echo "### Notify end of user_data ###"
touch /home/cloudus/user_data_finished
END_DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "BEGIN_DATE : $BEGIN_DATE"
echo "END_DATE : $END_DATE"
echo END