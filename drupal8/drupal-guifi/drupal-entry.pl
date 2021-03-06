#!/usr/bin/perl
# This script configures Drupal 6 for first time
#
use warnings;
use strict;

my $DRUPAL_DIR = "/usr/share/drupal/";
my $GUIFI_WEB_DIR = $DRUPAL_DIR."guifi-web/";
my $GUIFI_DEV_DIR = $DRUPAL_DIR."guifi-dev/";
my $GUIFI_MODULES_DIR = $GUIFI_WEB_DIR."sites/all/modules/";
my $GUIFI_THEMES_DIR = $GUIFI_WEB_DIR."sites/all/themes/";
my $GUIFI_DEV_DB = "guifi66_d7.sql";
my $GUIFI_DEV_DB_GZ = "$GUIFI_DEV_DB.gz";
my $GUIFI_DOMAIN = "http://flaugier.ddns.net/";

sub xdebug_php {
  print "Modify xdebug.ini file...\n";
  my $file = "/etc/php/7.0/apache2/conf.d/20-xdebug.ini";
  open(FILE, "<".$file) || die "File not found";
  my @lines = <FILE>;


  # Add php5-xdebug support
  my $xdebug = "xdebug.remote_enable=1
  xdebug.remote_handler=dbgp
  xdebug.remote_mode=req
  xdebug.remote_connect_back=1
  xdebug.remote_port=$ENV{XDEBUG_PORT}
  xdebug.remote_autostart=0\n";
  push(@lines, $xdebug);

  open(FILE, ">".$file) || die "File not found";
  print FILE @lines;
  close(FILE);
}

sleep 15; # We should wait for mariadb container being ready

print "Checking configurations...\n";

  &xdebug_php;
  if ($? != 0) {
    # Error
    die "Error setting xdebug configurations.\n";
  }

if (! -e $GUIFI_WEB_DIR."INSTALLED") {
  my $output = `rm -rf ${GUIFI_WEB_DIR}*`;
  if ($? != 0) {
    # Error
    die "Error purging Drupal dir.\n";
  }

  $output = `drush dl -y drupal-8 --destination=$DRUPAL_DIR --drupal-project-rename=guifi-web`;
  print $output;
  if ($? != 0) {
    # Error
    die "Error downloading Drupal dir.\n";
  }

  chdir($GUIFI_WEB_DIR);
  $output = `drush si -y --site-name=guifi.net --account-name=$ENV{DRUPAL_ADMIN} \\
   --account-pass=$ENV{DRUPAL_ADMIN_PWD} --db-url=mysqli://$ENV{GUIFI_USER_DB}:$ENV{GUIFI_USER_DB_PWD}\@database/$ENV{GUIFI_DB}`;
  if ($? != 0) {
    # Error
    die "Error in drush si command.\n";
  }

  # We should reduce privileges to avoid possible vulnerabilities
  $output = `chmod o-w /usr/share/drupal/guifi-web/sites/default/settings.php`;

  if ($? != 0) {
    # Error
    die "Error in chmod command.\n";
  }

  # We change permissions in budgets module
  $output = `chown -R www-data:www-data ${GUIFI_WEB_DIR}sites/default/files`;

  if ($? != 0) {
    # Error
    die "Error changing permissions budgets module.\n";
  }


  # Creating tmp dir & changing dir permissions
  $output = `mkdir -p ${GUIFI_WEB_DIR}sites/default/tmp && chown -R www-data:www-data ${GUIFI_WEB_DIR}sites/default/tmp`;
  if ($? != 0) {
     # Error
     die "Error in tmp dir creation.\n";
  }


  # Deleting all /tmp files
  $output = `rm -rf /tmp/*`;
  if ($? != 0) {
     # Error
     die "Error removing all temp files.\n";
  }


  # make INSTALLED file
  $output = `touch ${GUIFI_WEB_DIR}INSTALLED`;
  if ($? != 0) {
     # Error
     die "Error creating INSTALLED file.\n";
  }

  print "Guifi.net dev page successfully installed in Docker image!\n";
}
else {
  print "Already installed.\n";
}
