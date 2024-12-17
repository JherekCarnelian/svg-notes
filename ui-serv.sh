
usage="ERROR. Call should look like this:> ./$(basename $0) <(svg)File2View>"

. cliSVGaccess.sh.lib || { echo "ERROR. cliSVGaccess.sh.lib konnte nicht geladen werden. exit." ; exit 1; }
. ui-functions.inc.sh || { echo "ERROR. ui-functions.inc.sh konnte nicht geladen werden. exit." ; exit 1; }

FMTstr='\n\t%-20s%-100s\n'
File2View="${1:?$usage}"
Data2View="${File2View%.svg}"
SvgCMD_File2View="${File2View}.VIEW.svg"
SvgCMD_Data2View="${SvgCMD_File2View%.svg}"

if [[ ! -d "${Data2View}" ]] ; then
    mkdir -p "./${Data2View}/"
fi

echo File2View="${1:?$usage}"
echo Data2View="${File2View%.svg}"
echo SvgCMD_File2View="${File2View}.VIEW.svg"
echo SvgCMD_Data2View="${SvgCMD_File2View%.svg}"


if [[ -e "${File2View}.VIEW.svg" ]] ; then
    read -p "Kann VIEW.svg überschrieben werden? [j/n]: " -n 1 -r
    if [[ $REPLY =~ ^[YyJj]$ ]] ; then
        cp "$File2View" "${SvgCMD_File2View}"
        setRootSvgSize "$SvgCMD_File2View" 100vw 100vh
        if [[ ! -d "${SvgCMD_Data2View}" ]] ; then
            mkdir -p "./${SvgCMD_Data2View}/"
        fi
        rm "./${SvgCMD_Data2View}/*}"
        cp "${Data2View}/*" "${SvgCMD_Data2View}/"
    else
        echo "" 
        echo "Script wird verlassen. "
        exit 1
    fi
else
#    cp "$File2View" "${SvgCMD_File2View}"  || echo copy File2View ging schief
    mkdir -p "./${Data2View}/"
    mkdir -p "./${SvgCMD_Data2View}/"
    cliXML_save "$File2View" "${SvgCMD_File2View}" "${Data2View}/*" "${SvgCMD_Data2View}/" 
    setRootSvgSize "$SvgCMD_File2View" 100vw 100vh
fi


printf $FMTstr  SvgCMD_File2View ">|$SvgCMD_File2View>|<"

ActVIEWPORT_id="$(xdotool search --sync --onlyvisible --name  "Mozilla Firefox" )"
printf $FMTstr ActVIEWPORT_id ">|$ActVIEWPORT_id|<"

. ui-functions.inc.sh
# calc valid firstWords
tfW001="$(grep -Ee'function ([a-Z0-9_-]+) {' ui-functions.inc.sh | sed -e's/function /\^/' -e's/ {/\|/' | tr -d '\n')"
# ^r|^vb|^was_anderes|
tfW002=${tfW001%|}     # remove pipe at end of string, if exists
# ^r|^vb|^was_anderes
firstWords="$tfW002"

tfW005="$(grep -Ee'function ([a-Z0-9_-]+) {' cliSVGaccess.sh.lib | sed -e's/function /\^/' -e's/ {/\|/' | tr -d '\n')"
# ^r|^vb|^was_anderes|
tfW006=${tfW005%|}     # remove pipe at end of string, if exists
# ^r|^vb|^was_anderes
firstWords+="|$tfW006"


# echo "firstWords:>|"$firstWords"|<"
echo "ui-serv.sh <SVGfile>"
echo " help for help"
echo " "

# save history
history -w histories/history-$(date +%Y-%m-%d_%H%M%S)
SvgCMD_historyFile=history_SvgCMD
history -c
history -r "$SvgCMD_historyFile"


while read -rep"svgCmd:> " Zeile ; do
    history -s $Zeile
    if [[ $Zeile =~ ^exit$|^Exit$|^bye$|^quit$|^q$|^e$ ]] ; then
        echo "terminated by user. Thx for using. "
        history -a "$SvgCMD_historyFile"
        break;
    elif [[ $Zeile =~ ^history|^echo|^source ]] ; then
        eval "$Zeile"
    elif [[ $Zeile =~ ^help ]] ; then
        echo -e "$firstWords|eval (carefully!!)|bye|quit|q|e|exit|history|echo|help|save|saveAs|defs" | tr -d '^' | tr -s '|' '\n' | sort | column -x
    elif [[ $Zeile =~ ^save$ ]] ; then
        cliXML_save "$SvgCMD_File2View" "$File2View" "$SvgCMD_Data2View" "$Data2View" || echo "Hat nicht funktioniert"
    elif [[ $Zeile =~ ^saveAs$ ]] ; then
        read -p "Neuer Dateipfad?($File2View):> " -r NewFilePath
        if [[ ! -z $NewFilePath ]] ; then
            NewData2View="${NewFilePath%.svg}"
            mkdir -p "$NewData2View"
            cliXML_save "$SvgCMD_File2View" "$NewFilePath" "$SvgCMD_Data2View" "$NewData2View"  || echo "Hat nicht funktioniert"
        fi
    elif [[ $Zeile =~ ^defs ]] ; then
        eval "${Zeile#defs*}"
    elif [[ $Zeile =~ ^eval\   ]] ; then
        # be sure you understand this line can erase the whole system, if malicious commands are given
        (source cliSVGaccess.sh.lib; source ui-functions.inc.sh; eval "${Zeile#eval}")   # extra shell for catching exits of commands
    elif [[ $Zeile =~ $firstWords ]] ; then
        # be sure you understand this line can erase the whole system, if malicious commands are given
        (source cliSVGaccess.sh.lib; source ui-functions.inc.sh; eval "$Zeile")   # extra shell for catching exits of commands
    else
        echo "ERROR, Zeile beginnt mit keinem zulaessigen Schluesselwort '${Zeile%% *}'. Versuche help oder exit"
    fi
    
    
        


done    
    
