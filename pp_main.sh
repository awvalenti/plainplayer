# pkg install sox # libsox-fmt-mp3
# termux-setup-storage
# pulseaudio --start

pp_player_pid=

pp_main()
{
  unset -f pp_main

  play_vlc_windows()
  {
    local file args=()
    for file; do
      args+=("`cygpath -w \"$file\"`")
    done

    '/c/Program Files/VideoLAN/VLC/vlc' \
      -I dummy --one-instance -- "${args[@]}" >/dev/null 2>&1 &

    [ -z $pp_player_pid ] && pp_player_pid=$!
  }

  play_sox_linux()
  {
    stop_player
    play -q -- "$@" >/dev/null 2>&1 &
    pp_player_pid=$!
  }

  stop_player()
  {
    [ $pp_player_pid ] && [ -d /proc/$pp_player_pid ] && kill -- $pp_player_pid
  }

  local play_cmd
  if [[ $OSTYPE = msys ]]; then
    play_cmd=play_vlc_windows
  else
    play_cmd=play_sox_linux
  fi

  local valid_dirs=() dir
  for dir in "$@"; do
    [ -d "$dir" ] && valid_dirs+=("$dir")
  done

  local dirs_with_albums="${valid_dirs[@]}"

  # TODO Filter

  while :; do

    local albums=() index=1 album
    echo '00. Stop'
    for dir in "${dirs_with_albums[@]}"; do
      for album in "$dir"/*; do
        if [ -d "$album" ]; then
          printf "%02d. %s\n" $index "$album"
          albums[$index]=$album
          let ++index
        fi
      done
    done
    echo '99. Quit'

    local option files=()
    read -r -n 2 -p 'Choose album: ' option
    if ! [[ $option =~ ^[0-9][0-9]$ ]]; then
      printf " - invalid option\n\n"
    elif [ $option -eq 0 ]; then
      stop_player
      pp_player_pid=
      printf " - stopping\n\n"
    elif [ $option -eq 99 ]; then
      stop_player
      unset pp_player_pid
      printf " - exiting\n\n"
      return 2>/dev/null || exit
    elif [ $option -lt 0 ] || [ $option -ge $index ]; then
      printf " - non-existing album\n\n"
    else
      album="${albums[${option#0}]}"
      printf " - ok, let's play $album!\n\n"
      readarray -d '' audio_files < <(find "$album" \( -name '*.mp3' -or -name '*.flac' \) -print0 | sort -nz)
      $play_cmd "${audio_files[@]}"
    fi
  done
}

pp_main "$@"
