#!/bin/zsh

function goto_repo() {
  [[ $(pwd) == "${APP_DIR}" ]] && return 0
  cd ${APP_DIR}
  source .rvmrc 2>/dev/null
}

function current_branch() {
  basename $(git symbolic-ref HEAD)
}

function app_name() {
  git remote -v | grep "^[^[:space:]]*${1}[^[:space:]]*[[:space:]]" | sed 's/.*://;s/\.git.*//' | head -1
}

function usage_examples() {
  cat <<USAGE
  USAGE:

    $(basename $0) (push)    # => heroku run rails console -a $APP_NAME
    $(basename $0) (c | con | console)    # => heroku run rails console -a $APP_NAME
    $(basename $0) (p | pg | psql)        # => heroku pg:psql -a $APP_NAME
    $(basename $0) (rake) \$@              # => heroku run rake \$@ -a $APP_NAME
    $(basename $0) (remote | remotes)     # => git remote -v
    $(basename $0) (db|dbm|mig|migrate|db:migrate)   # => heroku run rake db:migrate -a $APP_NAME
USAGE
}

case $1 in
  '')
    usage_examples

    goto_repo
  ;;

  help|-help|-h|--help)
    usage_examples

    goto_repo
  ;;

  -edit | --edit) vim $0 ;;

  egit) goto_repo; vim .git/config ;;

  git) goto_repo; cat .git/config ;;
  
  remote | remotes) goto_repo; git remote -v;;

  config)
    shift
    if [[ "$1" =~ '=' ]]; then
      echo "$0 => config:set -- has equals"
      echo
      echo $0 config:set "$@"
      $0 config:set "$@"
    else
      echo "$0 => config:get -- there are no equals signs"
      echo
      echo $0 config:get
      $0 config:get
    fi ;;

  getconfig | config:get)
    if [ ${IS_LOCAL:-0} -eq 1 -o ${REMOTE_NAME:-not_set} == 'not_set' ]; then
      echo 'There is no remote for this stub...'
      break
    fi

    shift
    heroku config -a $APP_NAME
    ;;

  setconfig | config:set)
    if [ ${IS_LOCAL:-0} -eq 1 -o ${REMOTE_NAME:-not_set} == 'not_set' ]; then
      echo 'There is no remote for this stub...'
    else
      shift
      goto_repo
      echo heroku config:add $@ -a $APP_NAME
      heroku config:add $@ -a $APP_NAME
    fi
    ;;

# Usage: heroku config
# 
#  display the config vars for an app
# 
#  -s, --shell  # output config vars in shell format
# 
# Examples:
# 
#  $ heroku config
#  A: one
#  B: two
# 
#  $ heroku config --shell
#  A=one
#  B=two
# 
# Additional commands, type "heroku help COMMAND" for more details:
# 
#   config:get KEY                            #  display a config value for an app
#   config:set KEY1=VALUE1 [KEY2=VALUE2 ...]  #  set one or more config vars
#   config:unset KEY1 [KEY2 ...]              #  unset one or more config vars

  pushdb)
    if [ ${IS_LOCAL:-0} -eq 1 -o ${REMOTE_NAME:-not_set} == 'not_set' ]; then
      echo 'There is no remote for this stub...'
    else
      goto_repo
      git pull --rebase origin $(current_branch)
      git push origin $(current_branch)
      git push $REMOTE_NAME $(current_branch):master
      heroku run rake db:migrate -a $APP_NAME
    fi

    ;;

  pushdbc)
    if [ ${IS_LOCAL:-0} -eq 1 -o ${REMOTE_NAME:-not_set} == 'not_set' ]; then
      echo 'There is no remote for this stub...'
    else
      goto_repo
      git pull --rebase origin $(current_branch)
      git push origin $(current_branch)
      git push $REMOTE_NAME $(current_branch):master
      heroku run rake db:migrate -a $APP_NAME
      heroku run bea_user='josh+admin@getbeautified.com' rails console -a $APP_NAME && exit
    fi
    ;;

  push)
    if [ ${IS_LOCAL:-0} -eq 1 -o ${REMOTE_NAME:-not_set} == 'not_set' ]; then
      echo 'There is no remote for this stub...'
    else
      goto_repo
      git pull --rebase origin $(current_branch)
      git push origin $(current_branch)
      git push $REMOTE_NAME $(current_branch):master
    fi

    ;;

  pushc)
    if [ ${IS_LOCAL:-0} -eq 1 -o ${REMOTE_NAME:-not_set} == 'not_set' ]; then
      echo 'There is no remote for this stub...'
    else
      goto_repo
      git pull --rebase origin $(current_branch)
      git push origin $(current_branch)
      git push $REMOTE_NAME $(current_branch):master
      heroku run bea_user='josh+admin@getbeautified.com' rails console -a $APP_NAME && exit
    fi

    ;;

  log | l | logs)
    goto_repo

    shift
    if [ ${IS_LOCAL:-0} -eq 1 ]; then
      tail -f log/development.log
    else
      heroku logs -t -a $APP_NAME && exit
    fi
  ;;

  rake)
    goto_repo

    shift
    if [ ${IS_LOCAL:-0} -eq 1 ]; then
      bundle exec rake $@ && exit
    else
      heroku run rake $@ -a $APP_NAME && exit
    fi
  ;;

  db|dbm|mig|migrate|dbmigrate|db:migrate)
    goto_repo

    shift
    if [ ${IS_LOCAL:-0} -eq 1 ]; then
      bundle exec rake db:migrate
      RAILS_ENV=test bundle exec rake db:migrate
    else
      heroku run rake db:migrate -a $APP_NAME && exit
    fi
  ;;

  console | con | c)
    goto_repo

    export COLUMNS=9999

    [[ $LINES -lt 15 ]] && export LINES=38
    [[ $COLUMNS -lt 120 ]] && export COLUMNS=204

    if [ ${IS_LOCAL:-0} -eq 1 ]; then
      env bea_user='josh+vendor@getbeautified.com' rails console && exit
    else
      heroku run bea_user='josh+admin@getbeautified.com' rails console -a $APP_NAME && exit
    fi
  ;;

  psql | pg | p)
    goto_repo

    if [ ${IS_LOCAL:-0} -eq 1 ]; then
      psql beautified_development
    else
      heroku pg:psql -a $APP_NAME && exit
    fi
  ;;

  restart)
    goto_repo

    heroku ps:restart -a $APP_NAME && exit
  ;;

  *)
    goto_repo
    heroku $@ -a $APP_NAME && exit
  ;;

esac
