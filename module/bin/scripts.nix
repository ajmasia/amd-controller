{ pkgs, ... }:

{
  awake = pkgs.writeShellScriptBin "awake" ''
    CPU=$(${pkgs.coreutils}/bin/cat /proc/cpuinfo | ${pkgs.gnugrep}/bin/grep name | uniq | cut -d ':' -f2 | ${pkgs.gnused}/bin/sed -r "s/^\s+//g")
    BAT=0
    AC_STATUS=0
    DESKTOP=1 

    if [ -d "/sys/class/power_supply/BAT0" ]; then
      BAT=1 
      DESKTOP=0
      AC_STATUS=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC0/online)
    fi

    if [ ! -f /etc/amd-controller/config.json ]; then
      echo "Error: Configuration file not found at /etc/amd-controller/config.json."
      exit 1
    fi
    
    getPw() {
      echo $(${pkgs.jq}/bin/jq .modePowerLimits.$1 /etc/amd-controller/config.json)
    }

    SLOW_WITH_AC="--tctl-temp=95 --slow-limit=$(getPw ac.slow.average) --stapm-limit=$(getPw ac.slow.sustained) --fast-limit=$(getPw ac.slow.actual) --max-performance"
    SLOW_WITH_BATTERY="--tctl-temp=95 --slow-limit=$(getPw bat.slow.average) --stapm-limit=$(getPw bat.slow.sustained) --fast-limit=$(getPw bat.slow.actual) --power-saving"

    set_slow_profile() {
      if [[ ($BAT == "1" && $AC_STATUS == "1") || $DESKTOP == "1" ]]; then
        ${pkgs.ryzenadj}/bin/ryzenadj $SLOW_WITH_AC &>/dev/null
      else
        ${pkgs.ryzenadj}/bin/ryzenadj $SLOW_WITH_BATTERY &>/dev/null
      fi
    }

    set_slow_profile

    echo "$(date) - slow profile (power management service)" >> /var/log/power.log
  '';
}
