#!/bin/zsh

autoload -U promptinit

PROMPT_UNICODE=${PROMPT_UNICODE:-yes}
setopt prompt_subst

source $(dirname $0)/lib/color.zsh
source $(dirname $0)/lib/vcs.zsh
source $(dirname $0)/lib/infos.zsh

typeset -gA _PROMPT_CHR
if [[ "$PROMPT_UNICODE" == "yes" ]]; then
  _PROMPT_CHR[PREFIX]="╼╢"
  _PROMPT_CHR[SUFFIX]="╟╾"
  _PROMPT_CHR[HBAR]='─'
  _PROMPT_CHR[VBAR]='│'
  _PROMPT_CHR[CORNER_LU]='╭'
  _PROMPT_CHR[CORNER_LD]='╰'
  _PROMPT_CHR[CORNER_RU]='╮'
  _PROMPT_CHR[CORNER_RD]='╯'
  _PROMPT_CHR[ARR_LEFT]='◀'
else
  _PROMPT_CHR[PREFIX]="["
  _PROMPT_CHR[SUFFIX]="]"
  _PROMPT_CHR[HBAR]='-'
  _PROMPT_CHR[VBAR]='|'
  _PROMPT_CHR[CORNER_LU]=','
  _PROMPT_CHR[CORNER_LD]="'"
  _PROMPT_CHR[CORNER_RU]=','
  _PROMPT_CHR[CORNER_RD]="'"
  _PROMPT_CHR[ARR_LEFT]='<'
fi

local function prompt_block() {
  zparseopts -D -E -if:=cond
  local block_color="$1"
  shift
  echo -n "${cond:+"%($cond[2]."}${block_color}${_PROMPT_CHR[PREFIX]} $* "
  echo -n "${_PROMPT_CHR[SUFFIX]}${rpscolor}${cond:+".)"}"
}

local function dir_info() {
  local dircolor=$([[ -w $PWD ]] && echo "${pathcolor}" || echo "${ropathcolor}")
  prompt_block $dircolor "%(5~|%-1~/.../|)%3~"
}

local function venv_info() {
  if [[ -n "$VIRTUAL_ENV" ]] then
    local venvname=${VIRTUAL_ENV:t}
    if [[ $venvname == "venv" ]]; then
      venvname=${VIRTUAL_ENV:h:t}/${VIRTUAL_ENV:t}
    fi
    prompt_block $usercolor "venv: ${venvname}"
  fi
  if [[ -n "$CONDA_DEFAULT_ENV" ]] then
    prompt_block $usercolor "conda: ${CONDA_DEFAULT_ENV}"
  fi
}

local function theme_precmd() {
  local -a lines infoline_both infoline_left infoline_right middleline
  local x i filler i_width

  vcs_info

  infoline_left+=( "${rpscolor}${_PROMPT_CHR[CORNER_LU]}" )

  ### First, assemble the top line
  infoline_left+=("$(dir_info)")
  infoline_left+=("$(venv_info)")

  # Username & host
  infoline_right+=("$(prompt_block --if 1j ${gitdirty} "Jobs: %j" )")
  infoline_right+=($(prompt_block "" "${usercolor}%n${reset}@${hostcolor}%m${rpscolor}" ))
  infoline_right+=("${rpscolor}${_PROMPT_CHR[CORNER_RU]}")

  # remove color escapes, expand all remaining escapes and count the chars
  local infostr=($infoline_left $infoline_right)

  i_width=${#${(%)${(S)${(j::)infostr}//\%\{*\%\}}}}

  filler=$(printf "${_PROMPT_CHR[HBAR]}%.0s" {2..$((COLUMNS - $i_width))})
  #filler="${rpscolor}${(l:$(( $COLUMNS - $i_width))::$_PROMPT_CHR[HBAR]:)}"

  infoline_both=($infoline_left $filler $infoline_right)
  lines+=( ${(j::)infoline_both} )


  # middle info line, only shown if not empty

  middleline+=( "${rpscolor}${_PROMPT_CHR[VBAR]} ")

  if [[ -n ${vcs_info_msg_0_} ]]; then
    middleline+=( "$(vcs_char) ${vcs_info_msg_0_}${reset}" )
  fi

  i_width=${#${(%)${(S)${(j::)middleline}//\%\{*\%\}}}}
  filler=$(printf " %.0s" {4..$((COLUMNS - $i_width))})

  ### Now, assemble all prompt lines
  if [[ $#middleline > 1 ]] then
    lines+=( "${middleline}${filler}${rpscolor}${_PROMPT_CHR[VBAR]}" )
  fi

  lines+=( "${_PROMPT_CHR[CORNER_LD]}${_PROMPT_CHR[PREFIX]} ${usercolor}%#${reset} " )

  ### Finally, set the prompt
  PROMPT=${(F)lines}
  RPS1="$usercolor${_PROMPT_CHR[ARR_LEFT]}%(?::$exitcolor${_PROMPT_CHR[PREFIX]})\$(exitstatus)%(?::${_PROMPT_CHR[SUFFIX]})${stycolor}${_PROMPT_CHR[PREFIX]}$(sty)${rpscolor}${_PROMPT_CHR[SUFFIX]}${_PROMPT_CHR[CORNER_RD]}$reset"
}

add-zsh-hook precmd theme_precmd
