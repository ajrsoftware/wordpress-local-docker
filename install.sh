#!bin/bash

# https://developer.wordpress.org/cli/commands/

WP_CONFIG=wp-config.php;
URL=http://localhost:8000;
TITLE=wordpress-local-docker;
ADMIN_USER=admin;
ADMIN_PASS=password;
ADMIN_EMAIL=test@test.com;

# Update local packages & install git
echo "------------------------------------------------------------------------------------------------------------"
echo "Updating & installing local packages";
echo "------------------------------------------------------------------------------------------------------------"
apt-get update;
apt-get upgrade -y;

echo "------------------------------------------------------------------------------------------------------------"
echo "Installing git";
echo "------------------------------------------------------------------------------------------------------------"
apt-get install -y git;

# Install WP-CLI
echo "------------------------------------------------------------------------------------------------------------"
echo "Installing the WP CLI";
echo "------------------------------------------------------------------------------------------------------------"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
php wp-cli.phar --info;
chmod +x wp-cli.phar;
mv wp-cli.phar /usr/local/bin/wp;

# Update WP to latest stable
echo "------------------------------------------------------------------------------------------------------------"
echo "Updating WP CLI to the latest stable build";
echo "------------------------------------------------------------------------------------------------------------"
wp cli update --stable --yes --color --allow-root;

# Allow chance for MySQL to be ready & wait for config to be generated
echo "------------------------------------------------------------------------------------------------------------"
until [ -f $WP_CONFIG ]
do
     echo "$WP_CONFIG not found, waiting for it to be generated...";
     sleep 5;
done
echo "------------------------------------------------------------------------------------------------------------"
echo "$WP_CONFIG found...";

# Setup WP & base admin user
echo "------------------------------------------------------------------------------------------------------------"
echo "Auto installing WordPress";
echo "------------------------------------------------------------------------------------------------------------"
wp core install --url=$URL --title=$TITLE --admin_user=$ADMIN_USER --admin_password=$ADMIN_PASS --admin_email=$ADMIN_EMAIL --color --allow-root;

# Update WordPress core version
echo "------------------------------------------------------------------------------------------------------------"
echo "Updating WordPress to the latest stable build";
echo "------------------------------------------------------------------------------------------------------------"
wp core update --color --allow-root;

# Set correct permalink strucutre
echo "------------------------------------------------------------------------------------------------------------"
echo "Setting correct permalink structure";
echo "------------------------------------------------------------------------------------------------------------"
wp rewrite structure '/%postname%/' --hard --color --allow-root;

# Remove must-use dir & re-create
echo "------------------------------------------------------------------------------------------------------------"
echo "Cleaning up must-use plugins";
echo "------------------------------------------------------------------------------------------------------------"
rm -r wp-content/mu-plugins;
mkdir wp-content/mu-plugins;

# Setup any mu-plugins
echo "------------------------------------------------------------------------------------------------------------"
echo "Setting up must use plugins";
echo "------------------------------------------------------------------------------------------------------------"
# Define constants
touch wp-content/mu-plugins/env.php;
echo "<?php define('WP_ENVIRONMENT_TYPE', 'local');" >> wp-content/mu-plugins/env.php;

# Install the spatie ray WP plugin, see https://spatie.be/docs/ray/v1/installation-in-your-project/wordpress
git clone https://github.com/spatie/wordpress-ray.git wp-content/mu-plugins/wordpress-ray;
touch wp-content/mu-plugins/ray-loader.php;
echo "<?php require WPMU_PLUGIN_DIR.'/wordpress-ray/wp-ray.php';" >> wp-content/mu-plugins/ray-loader.php;

# Remove plugins that come with WP
echo "------------------------------------------------------------------------------------------------------------"
echo "Removing default plugins";
echo "------------------------------------------------------------------------------------------------------------"
wp plugin delete hello --color --allow-root;
wp plugin delete akismet --color --allow-root;

# Add ray config
echo "------------------------------------------------------------------------------------------------------------"
echo "Adding ray config to app/ray.php";
echo "------------------------------------------------------------------------------------------------------------"
tee -a ./ray.php << END
<?php
return [
    'host' => 'host.docker.internal',
    'port' => 23517,
    'remote_path' => null,
    'local_path' => null,
];
END

echo "------------------------------------------------------------------------------------------------------------"
echo "Environment ready.";
