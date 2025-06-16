#!/bin/bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

hsdk_fzf_env() {
	HSDK_ENV_TARGET="$(hsdk lse | awk -F '|' '
    BEGIN { 
      print "Name\tAliases\tDescription";
      name=""; alias=""; desc=""; is_multiline=0;
    }

    NR > 3 {
      # Remove leading/trailing spaces from each field
      for (i=1; i<=NF; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i);
      }

      if ($2 ~ /^[0-9]/) {
        if (is_multiline) print name "\t" alias "\t" desc;  # Print previous entry
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        gsub(/^[ \t]+|[ \t]+$/, "", $3);
        gsub(/^[ \t]+|[ \t]+$/, "", $5);
        name = $2; alias = $3; desc = $5;
        is_multiline = 1;
      } else { 
        gsub(/^[ \t]+|[ \t]+$/, "", $5);
        desc = desc " " $5;
      }
    }

    END { if (is_multiline) print name "\t" alias "\t" desc; }
    ' | column -t -s $'\t' | fzf-tmux -p --header='  HSDK Environment' --header-lines=1)"

	if [[ -z "$HSDK_ENV_TARGET" ]]; then
		return 0
	fi

	HSDK_ENV_NAME=$(echo -n "$HSDK_ENV_TARGET" | awk '{print $1}')
	HSDK_ENV_ALIAS=$(echo -n "$HSDK_ENV_TARGET" | awk '{print $2}')

	tmux new-window -n "hsdk/$HSDK_ENV_NAME ($HSDK_ENV_ALIAS)" "$CURRENT_DIR/hsdk-set-env.sh $HSDK_ENV_NAME $HSDK_ENV_ALIAS"
}

hsdk_fzf_env "$@"
