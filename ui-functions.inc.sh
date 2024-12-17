

if [[ ! $(type -t getRootSvgSize) ]] ; then
    echo "load cliSVGaccess.sh lib" 
    . cliSVGaccess.sh.lib  || { echo "ERROR. cliSVGaccess.sh.lib konnte nicht geladen werden. exit." ; exit 1; }
fi
function r {
    if [[ -n "$WSL_DISTRO_NAME" ]] ; then
	"${ProgDir}/reload-viewer.exe" "$ViewerWindowTitle" "$CMDwindowTitle" "$(basename "$SvgCMD_File2View")" || echo "Fehler in $FUNCNAME wsl-branch"
    else
	# we think we are on plain linux
	     xdotool key --window $ActVIEWPORT_id "CTRL+F5"
    fi
}

function svg_width {
    local usage="$FUNCNAME <width>"
    local Width="${1:?$usage}"

    xmlstarlet ed -L -N svg="http://www.w3.org/2000/svg" \
               -u "/svg:svg/@width" -v "$Width" \
               "$SvgCMD_File2View"
    r  # redraw display
}

function svg_height {
    local usage="$FUNCNAME <height>"
    local Height="${1:?$usage}"

    xmlstarlet ed -L -N svg="http://www.w3.org/2000/svg" \
               -u "/svg:svg/@height" -v "$Height" \
               "$SvgCMD_File2View"
    r  # redraw display
}

function ar {
    local usage="$FUNCNAME <none|XMinYMin..XMidYMid..XMaxYMax> [ <meet|slice> ]"
    local Position="${1:?$usage}"
    local Slice="${2}"
    xmlstarlet ed -L -N svg="http://www.w3.org/2000/svg" \
               -u "/svg:svg/@preserveAspectRatio" -v "$Position $Slice" \
               "$SvgCMD_File2View"
    r  # redraw display
}


function vb {
    local usage="$FUNCNAME <x> <y> [ <width> <height> ]"
    local pX=${1:?$usage}
    local pY=${2:-y}
    local pWidth=${3:-width}
    local pHeight=${4:-height}
    local X=tbd
    local Y=tbd
    local Width=tbd
    local Height=tbd
    
     echo vb wurde aufgerufen: ">|$FUNCNAME $pX $pY $pWidth $pHeight|<"

     # hart codiert x y w h
     if [[ $pX =~ [0-9]+ && $pY =~ [0-9]+ && $pWidth =~ [0-9]+ && $pHeight =~ [0-9]+ ]] ; then
         X=$pX
         Y=$pY
         Width=$pWidth
         Height=$pHeight

     elif [[ $pX =~ ^[a-Z]+ ]] ; then
         # definierte Ausschnitte
         ##
         echo definierter Ausschnitt
         case $pX in
             whole|all)
                 X=0;Y=0;Width=4200;Height=2970
                 ;;
             q1|Q1)
                 X=0;Y=0;Width=2100;Height=1485
                 ;;
             q2|Q2)
                 X=2100;Y=0;Width=2100;Height=1485
                 ;;
             q3|Q3)
                 X=0;Y=1485;Width=2100;Height=1485
                 ;;
             q4|Q4)
                 X=2100;Y=1485;Width=2100;Height=1485
                 ;;
             
         esac
         
     elif [[ $pWidth == width && $pHeight == height ]] ; then
         # bestimmte Positionen
         ##
         local tVB="$(getViewBox "$SvgCMD_File2View")"
          Width=$(echo "$tVB" | cut -d' ' -f 3 )
         Height=$(echo "$tVB" | cut -d' ' -f 4 )        
     else
         echo ERROR. Format wurde nicht erkannt.
     fi         






   printf $FMTstr "vb wird ausgeführt:"  ">|$FUNCNAME $X $Y $Width $Height|<"
         xmlstarlet ed -L -N svg="http://www.w3.org/2000/svg" \
                    -u "/svg:svg/@viewBox" -v "$X $Y $Width $Height" \
                   "$SvgCMD_File2View"
   

     
        
    r  # redraw display
}

function was_anderes {
    echo sth else wurde aufgerufen
}

function getOrSet {
    local usage="$FUNCNAME <XPath2ElemOrAttribute> <''|NLflag> [ <newValue> ]"
    local path2check="${1:?$usage}"
    local FlagNL="${2?$usage}"
    local NewVal="${3:noValue}"


    
    cliXML_getOrSetElemValue "$SvgCMD_File2View" "$path2check" "$FlagNL" "$NewVal"

    if [[ ! -z $NewVal ]] ; then
        r # redraw
    fi
    
}

function show_historyFile {
    printf "$FMTstr" "historyFile" "$SvgCMD_historyFile"
    echo "---"
    cat "$SvgCMD_historyFile"
    echo "---"
    
}


function addNewTpl {
    local usage="$FUNCNAME <uniqueID> <tplname>"
    local uniqueID="${1:?$usage}"
    local tplname="${2:?$usage}"

    if [[ ! -e $tplname ]] ; then
        echo "ERROR: tplname existiert nicht. >|$tplname|<"
        return 1
    fi
    
    cliXML_addNewTpl "$SvgCMD_File2View" "$uniqueID" "$tplname"

    r # redraw 
    }

function addSubTpl {
    local usage="$FUNCNAME <uniqueID> <path2parent> <tplname>"
    local uniqueID="${1:?$usage}"
    local path2parent="${2:?$usage}"
    local tplname="${3:?$usage}"

    if [[ ! -e $tplname ]] ; then
        echo "ERROR: tplname existiert nicht. >|$tplname|<"
        return 1
    fi
    
    cliXML_addSubTpl "$SvgCMD_File2View" "$uniqueID" "$path2parent" "$tplname"

    # ein paar notwendige Anpassungen, weil replace-NEW-by... verwendet wird
    move $uniqueID 30 60
    
    r # redraw 
    }

function addNewImage {
    local usage="$FUNCNAME <uniqueID> <tplname> <path2image>"
    local uniqueID="${1:?$usage}"
    local tplname="${2:?$usage}"
    local path2image="${3:?$usage}"

    if [[ ! -r $path2image ]] ; then
        echo "FEHLER in $FUNCNAME : nicht lesbar, Abbruch path2image:>|$path2image|<"
        return 1
    fi

        local hatTplNameBildelement="$(xmlstarlet sel -N s=http://www.w3.org/2000/svg \
                     -t -v "boolean(//s:image[@name='Bildelement'])" \
                     "$tplname")"

    if [[ $hatTplNameBildelement == false ]] ; then
           echo "FEHLER: $FUNCNAME param tplname kein image tpl. >|$tplname|<"
           return 1
    fi

    addNewTpl $uniqueID "$tplname" 


    cp "./$path2image" "./${SvgCMD_Data2View}/" || echo cp hat nicht funktioniert

    set -v ; set -x    
    local path2image_basename="$(basename $path2image)"

    cliXML_getOrSetElemValue "$SvgCMD_File2View" "//s:g[@id='$uniqueID']//s:image[@name='Bildelement']/@href" newLine "${SvgCMD_Data2View}/${path2image_basename}"
    set +v ; set +x 
    r 
    
    }

function addLastClip {
    local usage="$FUNCNAME <uniqueID> <tplname>"
    local uniqueID="${1:?$usage}"
    local tplname="${2:?$usage}"


    set -v ; set -x
    local path2image="${ClipBoardDir}/$(ls -1 -t  "${ClipBoardDir}/" | head -n 1 | tr -d '\n')"

    if [[ ! -r "$path2image" ]] ; then
        echo "FEHLER in $FUNCNAME : nicht lesbar, Abbruch path2image:>|$path2image|<"
        return 1
    fi
    set +v ; set +x 
    local hatTplNameBildelement="$(xmlstarlet sel -N s=http://www.w3.org/2000/svg \
                     -t -v "boolean(//s:image[@name='Bildelement'])" \
                     "$tplname")"

    if [[ $hatTplNameBildelement == false ]] ; then
           echo "FEHLER: $FUNCNAME param tplname kein image tpl. >|$tplname|<"
           return 1
    fi

    addNewTpl $uniqueID "$tplname" 

    cp "$path2image" "${SvgCMD_Data2View}/" || echo cp hat nicht funktioniert

    set -v ; set -x    
    local path2image_basename="$(basename "$path2image")"

    cliXML_getOrSetElemValue "$SvgCMD_File2View" "//s:g[@id='$uniqueID']//s:image[@name='Bildelement']/@href" newLine "${SvgCMD_Data2View}/${path2image_basename}"
    set +v ; set +x 
    r  # redraw
    
    }

function deleteID {
    local usage="$FUNCNAME <elemID> delete "
    local elemID=${1:?$usage}
    local flag=${2:?$usage}

    cliXML_delete "$SvgCMD_File2View" "$elemID" "$flag"

    r # redraw
}

function writeTitelZeile {
    local usage="$FUNCNAME <elemID> <Textzeile> "
    local elemID=${1:?$usage}
    local textZeile=${2:?$usage}

     # jede g Gruppe hat nur 1 Titelzeile, wirklich ?
    cliXML_getOrSetElemValue "$SvgCMD_File2View" "//s:g[@id='$elemID']//s:*[@name='TitelZeile']" '' "$textZeile"

    r # redraw
    
    }

function writeTextzeile {
    local usage="$FUNCNAME <elemID> <Textzeile> "
    local elemID=${1:?$usage}
    local textZeile=${2:?$usage}


    cliXML_getOrSetElemValue "$SvgCMD_File2View" "//s:g[@id='$elemID']//s:*[@name='Klartext']" '' "$textZeile"

    r # redraw
    
    }

function writeKlartext {
    local usage="$FUNCNAME <elemID>"
    local elemID="${1:?$usage}"

    cliSVG_insertTextSpans "$SvgCMD_File2View" "//s:g[@id='$elemID']//s:*[@name='Klartext']"
    r # redraw    
    }

function addAttribute {
    local usage="$FUNCNAME <XPath2element> <NameOfAttribute> [ <newValue> ]"    
    local XPath2target="${1:?$usage}"
    local AttrName="${2:-?$usage}"
    local NewVal="${3:noValue}"

    cliXML_addAttribute "$SvgCMD_File2View" "$XPath2target" "$AttrName" "$NewVal"
    
}


function set_g_PositionById {
    local usage="$FUNCNAME <elemID> <x> <y> "
    local elemID=${1:?$usage}
    local pX=${2:?$usage}
    local pY=${3:?$usage}

    # transform kann verschiedene Parameter enthalten
    # geändert werden soll nur translate
    # alles andere soll bleiben wie es ist

    local actTransformValue="$(xmlstarlet sel -N svg="http://www.w3.org/2000/svg" \
               -t -m "/svg:svg//svg:g[@id='${elemID}']/@transform" -v "." \
               "$SvgCMD_File2View" \
               )"
    echo "actTransformValue=>|$actTransformValue|<"    

    local pat="translate([0-9]\+,[0-9]\+)"
    local rpl="translate($pX,$pY)"
    local newTransformValue="$(echo "$actTransformValue" | sed "s/$pat/$rpl/")"

    if [[ $actTransformValue =~ translate ]] ; then
          newTransformValue="$(echo "$actTransformValue" | sed "s/$pat/$rpl/")"
    else
          newTransformValue="$actTransformValue $rpl"
    fi



    
    xmlstarlet ed -L -N svg="http://www.w3.org/2000/svg" \
               -u "/svg:svg//svg:g[@id='${elemID}']/@transform" -v "$newTransformValue" \
               "$SvgCMD_File2View"
    r  # redraw display

    
}

function move {
    set_g_PositionById "$@"

        # echo "Dollar1: $1 SvgCMD_File2View: $SvgCMD_File2View"
    local actTransformValue="$(xmlstarlet sel -N svg="http://www.w3.org/2000/svg" \
               -t -m "/svg:svg//svg:g[@id='${1}']/@transform" -v "." \
               "$SvgCMD_File2View" \
               )"

        cliXML_getOrSetElemValue "$SvgCMD_File2View" "//s:g[@id='$1']/s:text/s:tspan" '' "$1 - $actTransformValue"

  r # redraw
        
}

function set_g_ScaleById {
    local usage="$FUNCNAME <elemID> <scale_X> <scale_Y> "
    local elemID=${1:?$usage}
    local pX=${2:?$usage}
    local pY=${3:?$usage}

    # transform kann verschiedene Parameter enthalten
    # geändert werden soll nur scale
    # alles andere soll bleiben wie es ist

    local actTransformValue="$(xmlstarlet sel -N svg="http://www.w3.org/2000/svg" \
               -t -m "/svg:svg//svg:g[@id='${elemID}']/@transform" -v "." \
               "$SvgCMD_File2View" \
               )"
    local newTransformValue=""
    local pat="scale([0-9.]\+,[0-9.]\+)"
    local rpl="scale($pX,$pY)"
    
    echo "actTransformValue=>|$actTransformValue|<"

    if [[ $actTransformValue =~ scale ]] ; then
          newTransformValue="$(echo "$actTransformValue" | sed "s/$pat/$rpl/")"
    else
          newTransformValue="$actTransformValue $rpl"
    fi

    xmlstarlet ed -L -N svg="http://www.w3.org/2000/svg" \
               -u "/svg:svg//svg:g[@id='${elemID}']/@transform" -v "$newTransformValue" \
               "$SvgCMD_File2View"
    r  # redraw display

    
}

function scale {
    set_g_ScaleById "$@"

    # echo "Dollar1: $1 SvgCMD_File2View: $SvgCMD_File2View"
    local actTransformValue="$(xmlstarlet sel -N svg="http://www.w3.org/2000/svg" \
               -t -m "/svg:svg//svg:g[@id='${1}']/@transform" -v "." \
               "$SvgCMD_File2View" \
               )"
    
    cliXML_getOrSetElemValue "$SvgCMD_File2View" "//s:g[@id='$1']/s:text/s:tspan" '' "$1 - $actTransformValue"

    r # redraw
}

function writeKartenText {
    local usage="$FUNCNAME <elemID>"
    local elemID="${1:?$usage}"


    cliSVG_insertTextSpans "$SvgCMD_File2View" "//s:g[@id='$elemID']//s:*[@name='KartenText']"
    r # redraw
}

function v {
    echo "navigation via digits block or asdwsx +/- or s/S to zoom in/out"
    set -xv

    set +xv
    while true ; do
           VB="XYWH $(getViewBox "$SvgCMD_File2View")"
           set $VB   # $2..5  X Y Width Height
           echo "$SvgCMD_File2View"
           echo "gib mal VB aus >|$VB|<"
           echo "gib mal 2 3 4 5 aus >|$2 $3 $4 $5|<"
        read -rsn1 Key
#       echo "Key=>|$Key|<"
         case $Key in
             q|e|'exit'|quit|Q|E)
             #                 X=0;Y=0;Width=4200;Height=2970
                 break
                 ;;
             a|5)
                 VBorg="XYWH $(getViewBox "$File2View")"
                 set $VBorg
                 vb $2 $3 $4 $5
                 r
                 ;;
             ↑|8)
# X=0;Y=0;Width=2100;Height=1485
                 echo go n
                 vb $2 $(bc <<< "$3 - $5 / 10") $4 $5
                 r
                 ;;
             ↗|9)
# X=0;Y=0;Width=2100;Height=1485
                 echo go ne
                 ;;
             →|6)
                 #                 X=0;Y=1485;Width=2100;Height=1485
                   echo go e
                   vb $(bc <<< "$2 + $4 / 10") $3 $4 $5
                 ;;
             ↘|3)
# X=0;Y=0;Width=2100;Height=1485
                 echo go se
                 ;;

             ↓|2)
                 #                 X=2100;Y=0;Width=2100;Height=1485
                   echo go s
                   vb $2 $(bc <<< "$3 + $5 / 10") $4 $5
                   r
                 ;;
             ↙|1)
                 #                 X=2100;Y=0;Width=2100;Height=1485
                 echo go sw
                 ;;
             ←|4)                   
                 #                 X=2100;Y=1485;Width=2100;Height=1485
                   echo go w
                   vb $(bc <<< "$2 - $4 / 10") $3 $4 $5
                 ;;
             ↖|7)                   
                 #                 X=2100;Y=1485;Width=2100;Height=1485
                 echo go nw
                 ;;
             S|·|-)                   
                 #                 X=2100;Y=1485;Width=2100;Height=1485
                 echo zoom out
                 newWidth=$(bc <<< "$4 * 1.5")
                 newHeight=$(bc <<< "$5 * 1.5")
                 vb $(bc <<< "$2 - (($newWidth - $4) / 2)") $(bc <<< "$3 - (( $newHeight - $5 ) / 2)") $newWidth $newHeight                 
                 ;;

             s|·|+)                   
                 #                 X=2100;Y=1485;Width=2100;Height=1485
                 echo 'zoom in'
                 newWidth=$(bc <<< "$4 / 1.5")
                 newHeight=$(bc <<< "$5 / 1.5")
                 vb $(bc <<< "$2 + (($4 - $newWidth) / 2)") $(bc <<< "$3 + (( $5 - $newHeight) / 2)") $newWidth $newHeight
                 ;;
             
         esac

       
        Z="$Key"
        if [[ $Z == e ]] ; then
            break
        elif [[ $Z == h || $Z == ? ]]  ; then
            echo "E for exit / h for help "
            
        fi

    done
}

function zoomHandle {
     local usage="$FUNCNAME <''|irgendwas> "
     local flag=${1:?$usage}

     getOrSet "//s:text[@name='handle-id']//s:*/@font-size" 'NL' 12mm
     getOrSet "//s:text[@name='handle-id']/@fill" 'NL' 'darkgreen'
 }

function resetHandle {
     local usage="$FUNCNAME <''|irgendwas> "
     local flag=${1:?$usage}

     getOrSet "//s:text[@name='handle-id']//s:*/@font-size" 'NL' 14
     getOrSet "//s:text[@name='handle-id']/@fill" 'NL' 'black'

     r # redraw
 }

function hideHandles {
    local usage="$FUNCNAME <''|irgendwas> "
    local flag=${1:?-$usage}

    getOrSet "//s:text[@name='handle-id']/@visibility" 'NL' hidden

    r # redraw
}

function showHandles {
    local usage="$FUNCNAME <''|irgendwas> "
    local flag=${1:?-$usage}

    getOrSet "//s:text[@name='handle-id']/@visibility" 'NL' visible

    r # redraw
}

function blattTitel {
    local usage="$FUNCNAME <''|Titelzeile> "
    local TitelZeileOderNichts="${1:?-$usage}"

    getOrSet "//s:g[@id='BlattTitel']//s:tspan[@name='TitelText']" '' "$TitelZeileOderNichts"

    if [[ ! -z "$TitelZeileOderNichts" ]] ; then
        r # redraw
    fi
    }
function blattSubTitel {
    local usage="$FUNCNAME <''|SubTitelzeile> "
    local TitelZeileOderNichts="${1:?-$usage}"

    getOrSet "//s:g[@id='BlattTitel']//s:tspan[@name='UntertitelText']" '' "$TitelZeileOderNichts"

    if [[ ! -z "$TitelZeileOderNichts" ]] ; then
        r # redraw
    fi
    }
function blattSub2Titel {
    local usage="$FUNCNAME <''|Titelzeile> "
    local TitelZeileOderNichts="${1:?-$usage}"

    getOrSet "//s:g[@id='BlattTitel']//s:tspan[@name='Untertitel2Text']" '' "$TitelZeileOderNichts"

    if [[ ! -z "$TitelZeileOderNichts" ]] ; then
        r # redraw
    fi
    }
