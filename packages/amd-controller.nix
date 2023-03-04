{ config, lib, pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
    name = "amd-controller";

    amd-controller = pkgs.writeShellScriptBin "amd-controller" ''
    COLOR_OFF='\033[0m' # Text Reset
    GREEN='\033[0;32m'  # Green
    YELLOW='\033[0;33m' # Yellow
    CPU=$(${pkgs.coreutils}/bin/cat /proc/cpuinfo | ${pkgs.gnugrep}/bin/grep name | uniq | cut -d ':' -f2 | ${pkgs.gnused}/bin/sed -r "s/^\s+//g")
    BAT=0
    AC_STATUS=0
    DESKTOP=1 
    USER=$USER

    if [ -d "/sys/class/power_supply/BAT0" ]; then
      BAT=1 
      DESKTOP=0
      AC_STATUS=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC0/online)
    fi

    if [ ! -f /etc/amd-controller/config.json ]; then
      echo "Error: Configuration file not found at /etc/amd-controller/config.json."
      exit 1
    fi

    getPowerValue() {
      echo $(${pkgs.jq}/bin/jq .modePowerLimits.$1 /etc/amd-controller/config.json)
    }

    wrappedRyzenadj() {
      if [[ $USER != "" ]]; then
         sudo ${pkgs.ryzenadj}/bin/ryzenadj $@
      else
         ${pkgs.ryzenadj}/bin/ryzenadj $@
      fi
    }

    SLOW_WITH_AC="--tctl-temp=95 --slow-limit=$(getPowerValue ac.slow.average) --stapm-limit=$(getPowerValue ac.slow.sustained) --fast-limit=$(getPowerValue ac.slow.actual) --max-performance"
    SLOW_WITH_BATTERY="--tctl-temp=95 --slow-limit=$(getPowerValue bat.slow.average) --stapm-limit=$(getPowerValue bat.slow.sustained) --fast-limit=$(getPowerValue bat.slow.actual) --power-saving"

    MEDIUM_WITH_AC="--tctl-temp=95 --slow-limit=$(getPowerValue ac.medium.average) --stapm-limit=$(getPowerValue ac.medium.sustained) --fast-limit=$(getPowerValue ac.medium.actual) --max-performance"
    MEDIUM_WITH_BATTERY="--tctl-temp=95 --slow-limit=$(getPowerValue bat.medium.average) --stapm-limit=15000 --fast-limit=25000 --power-saving"

    HIGH_WITH_AC="--tctl-temp=95 --slow-limit=$(getPowerValue ac.high.average) --stapm-limit=$(getPowerValue ac.high.sustained) --fast-limit=$(getPowerValue ac.high.actual) --max-performance"
    HIGH_WITH_BATTERY="--tctl-temp=95 --slow-limit=$(getPowerValue bat.high.average) --stapm-limit=$(getPowerValue bat.high.sustained) --fast-limit=$(getPowerValue bat.high.actual) --power-saving"

    FIRE_WITH_AC="--tctl-temp=95 --slow-limit=$(getPowerValue ac.fire.average) --stapm-limit=$(getPowerValue ac.fire.sustained) --fast-limit=$(getPowerValue ac.fire.actual) --max-performance"
    FIRE_WITH_BATTERY="--tctl-temp=95 --slow-limit=$(getPowerValue bat.fire.average) --stapm-limit=$(getPowerValue bat.fire.sustained) --fast-limit=$(getPowerValue bat.fire.actual) --power-saving"

    SILENT_WITH_AC="--tctl-temp=95 --slow-limit=54000 --stapm-limit=45000 --fast-limit=65000 --max-performance"
    SILENT_WITH_BATTERY="--tctl-temp=95 --slow-limit=30000 --stapm-limit=30000 --fast-limit=35000 --power-saving"

    BALANCE_WITH_AC="--tctl-temp=95 --slow-limit=60000 --stapm-limit=54000 --fast-limit=65000 --max-performance"
    BALANCE_WITH_BATTERY="--tctl-temp=95 --slow-limit=30000 --stapm-limit=30000 --fast-limit=35000 --power-saving"

    help() {
      printf "''${YELLOW}Slimbook ''${CPU} profile updater tool''${COLOR_OFF}\n\n"
      printf "''${GREEN}Usage: sudo amd-controller [command <option>] [option]''${COLOR_OFF}\n\n"

      printf "''${YELLOW}Commands:''${COLOR_OFF}\n"
      echo "set <option>       Set processor profile"
      echo

      printf "''${YELLOW}Options:''${COLOR_OFF}\n"
      echo "-s, --slow              Set your processor to work with slow profile"
      echo "-m, --medium            Set your processor to work with medium profile"
      echo "-h, --high              Set your processor to work with high profil"
      echo "-f, --fire              Set your processor to work with fire profil"
      echo "-sl --silent            Set your processor to work with system silent profil"
      echo "-bl --balance           Set your processor to work with system balance profil"
      echo "-ps, --power-saving     Tune your processor for power saving"
      echo "-mp, --max-performance  Tune your processor for max performance"
      echo

      printf "''${YELLOW}Flags:''${COLOR_OFF}\n"
      echo "-h, --help         Show CLI help"
      echo "-i, --info         Show processor profile info"
      echo

      printf "''${GREEN}Example: Type 'amd-controller set -s' to set your processor to work with a slow profile''${COLOR_OFF}\n"
      echo
      echo "Inspired by: https://shorturl.at/hqrAL"
      echo "Review params for other AMD processors here: https://shorturl.at/jHJ35"
    }

    set_slow_profile() {
      if [[ ($BAT == "1" && $AC_STATUS == "1") || $DESKTOP == "1" ]]; then
        wrappedRyzenadj $SLOW_WITH_AC &>/dev/null
      else
        wrappedRyzenadj $SLOW_WITH_BATTERY &>/dev/null
      fi

      printf "''${GREEN}🛠  SLOW profile set successfully for $CPU processor\n"
    }

    set_medium_profile() {
      echo $MEDIUM_WITH_AC
      echo $MEDIUM_WITH_BATTERY

      if [[ ($BAT == "1" && $AC_STATUS == "1") || $DESKTOP == "1" ]]; then
        wrappedRyzenadj $MEDIUM_WITH_AC &>/dev/null
      else
        wrappedRyzenadj $MEDIUM_WITH_BATTERY &>/dev/null
      fi

      printf "''${GREEN}🛠  MEDIUM profile set successfully for $CPU processor\n"
    }

    set_high_profile() {
      if [[ ($BAT == "1" && $AC_STATUS == "1") || $DESKTOP == "1" ]]; then
        wrappedRyzenadj $HIGH_WITH_AC &>/dev/null
      else
        wrappedRyzenadj $HIGH_WITH_BATTERY &>/dev/null
      fi

      printf "''${GREEN}🛠  HIGH profile set successfully for $CPU processor\n"
    }

    set_fire_profile() {
      if [[ ($BAT == "1" && $AC_STATUS == "1") || $DESKTOP == "1" ]]; then
        wrappedRyzenadj $FIRE_WITH_AC &>/dev/null
      else
        wrappedRyzenadj $FIRE_WITH_BATTERY &>/dev/null
      fi

      printf "''${GREEN}🛠  FIRE profile set successfully for $CPU processor\n"
    }

    set_silent_profile() {
      if [[ ($BAT == "1" && $AC_STATUS == "1") || $DESKTOP == "1" ]]; then
        wrappedRyzenadj $SILENT_WITH_AC &>/dev/null
      else
        wrappedRyzenadj $SILENT_WITH_BATTERY  &>/dev/null
      fi

      printf "''${GREEN}🛠 SILENT profile set successfully for $CPU processor\n"
    }

    set_balance_profile() {
      if [[ ($BAT == "1" && $AC_STATUS == "1") || $DESKTOP == "1" ]]; then
        wrappedRyzenadj $BALANCE_WITH_AC &>/dev/null
      else
        wrappedRyzenadj $BALANCE_WITH_BATTERY &>/dev/null
      fi

      printf "''${GREEN}🛠 BALANCE profile set successfully for $CPU processor\n"
    }

    set_power_saving_profile() {
      wrappedRyzenadj --power-saving

      printf "''${GREEN}🛠 POWER SAVING profile set successfullys for $CPU processor\n"
    }

    set_max_performance_profile() {
      wrappedRyzenadj --max-performance

      printf "''${GREEN}🛠 MAX PEPERFORMANCE profile set successfullys for $CPU processor\n"
    }

    show_processor_profile_info() {
      STAPM_LIMIT=$(wrappedRyzenadj -i | ${pkgs.gnugrep}/bin/grep "STAPM LIMIT" | ${pkgs.gawk}/bin/awk '{print $5}')
      PPT_LIMIT_FAST=$(wrappedRyzenadj -i | ${pkgs.gnugrep}/bin/grep "PPT LIMIT FAST" | ${pkgs.gawk}/bin/awk '{print $6}')
      PPT_LIMIT_SLOW=$(wrappedRyzenadj -i | ${pkgs.gnugrep}/bin/grep "PPT LIMIT SLOW" | ${pkgs.gawk}/bin/awk '{print $6}')
      CCLK_BOOST_SETPOINT=$(wrappedRyzenadj -i | ${pkgs.gnugrep}/bin/grep "CCLK Boost SETPOINT" | ${pkgs.gawk}/bin/awk '{print $6}')
      CCLK_BUSY_VALUE=$(wrappedRyzenadj -i | ${pkgs.gnugrep}/bin/grep "CCLK BUSY VALUE" | ${pkgs.gawk}/bin/awk '{print $6}')

      printf " ''${GREEN}''${CPU} currrent profile info''${COLOR_OFF}\n"
      printf "BAT present: ''${YELLOW}$([[ $BAT == 1 ]] && echo "YES" || echo "NO")''${COLOR_OFF}\n" 
      printf "AC present: ''${YELLOW}$([[ $AC_STATUS == 1 ]] && echo "YES" || echo "NO")''${COLOR_OFF}\n" 
      printf "Desktop environtment: ''${YELLOW}$([[ $DESKTOP == 1 ]] && echo "YES" || echo "NO")''${COLOR_OFF}\n\n" 

      printf "Param               | Description                     | Value  \n"
      echo "--------------------|---------------------------------|--------"
      printf "STAPM LIMIT         | Sustained Power Limit (mW)      | ''${STAPM_LIMIT}\n"
      printf "PPT LIMIT SLOW      | Average Power Limit (mW)        | ''${PPT_LIMIT_SLOW}\n"
      printf "PPT LIMIT FAST      | Actual Power Limit (mW)         | ''${PPT_LIMIT_FAST}\n"
      printf "CCLK BOOST SETPOINT | Power Saving tune value (mW)    | ''${CCLK_BOOST_SETPOINT}\n"
      printf "CCLK BUSY VALUE     | Max Performance tune value (mW) | ''${CCLK_BUSY_VALUE}\n\n"

      printf "''${YELLOW}STAPM (Skin Temperature Aware Power Management)''${COLOR_OFF}\n"
      printf "Your device's STAPM configuration is set by the manufacturer and differs depending on the processor u${pkgs.gnused}/bin/sed and the form factor of the device\n\n"

      printf "''${YELLOW}PPT (Package Power Tracking)''${COLOR_OFF}\n"
      printf "PPT is a measurement of power to the CPU Socket on the motherboard and not the CPU itself\n\n"

      printf "''${YELLOW}More info''${COLOR_OFF}\n"
      printf "Ryzenadj: https://github.com/FlyGoat/RyzenAdj\n"
      printf "AMDController: https://ryzencontroller.com/\n\n"

      printf "''${GREEN}For more help, please type 'amd-controller -h, --help' ''${COLOR_OFF}\n\n"
    }

    case $1 in
    set)
      case $2 in
      -b | --base)
        set_base_profile
        ;;
      -s | --slow)
        set_slow_profile
        ;;
      -m | --medium)
        set_medium_profile
        ;;
      -h | --high)
        set_high_profile
        ;;
      -f | --fire)
        set_fire_profile
        ;;
      -sl | --silent)
        set_silent_profile
        ;;
      -bl | --balance)
        set_balance_profile
        ;;
      -ps | --power-saving)
        set_power_saving_profile
        ;;
      -mp | --max-performance)
        set_max_performance_profile
        ;;
      *)
        printf "''${YELLOW}Invalid option\n''${COLOR_OFF}"
        help
        ;;
      esac
      ;;
    -i | --info)
      show_processor_profile_info
      ;;
    -h | --help)
      help
      ;;
    *)
      printf "''${YELLOW}Invalid command or option\n''${COLOR_OFF}"
      help
      ;;
    esac
    '';

    src = builtins.path { path = ./.; name = "sources"; };

    installPhase = ''
      mkdir -p $out/bin
      cp ${amd-controller}/bin/amd-controller /$out/bin
    '';
  }
