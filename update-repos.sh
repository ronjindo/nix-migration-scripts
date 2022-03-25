#!/bin/bash

base="/code/lsport"
current_dir=$(pwd)

echo "updating repositories ..."
echo
for r in "backend" "web" "db-consumer" "db-repository" "development-environment" "devops" "logger" \
          "lsports-messages-proxy" "migrator" "pre-match-updates-db-updater" "queue-loader" "virtual-screen" "worker" ; 
  do echo && echo "updating $r ..." && cd $base/$r && git stash && git pull; cd $current_dir; done

echo
for r in "lsport-data-importer" "paypal-wrapper" ; 
  do echo && echo "updating packages/$r ..." && cd $base/packages/$r && git pull; cd $current_dir; done

echo
for r in "bookmaker-disabler" "change-user-subscriptions" "clear-recovery-password-tokens" "create-paypal-plans-products" \
          "events-archiver" "import-bookmakers" "import-inplay-events" "import-leagues" "import-locations" "import-markets" \
          "import-outright-leagues" "import-pre-match-events" "import-sports" "market-disabler" "navbar-generate" "order-inplay-events" \
          "remove-canceled-events" "import-in-progress-events-without-in-play-feed-updates" ; 
  do echo && echo "updating cron-jobs/$r ..." && cd $base/cron-jobs/$r && git pull; cd $current_dir; done

