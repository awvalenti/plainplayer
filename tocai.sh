# pkg install sox # libsox-fmt-mp3
# termux-setup-storage
# pulseaudio --start

tocai_player_pid=

tocai_main()
(
  unset -f tocai_main

  play_vlc_windows()
  {
    local file
    local args=()
    for file; do
      args+=("$(cygpath -w "$file")")
    done

    '/c/Program Files/VideoLAN/VLC/vlc' \
      -I dummy --one-instance -- "${args[@]}" >/dev/null 2>&1 &

    [ -z $tocai_player_pid ] && tocai_player_pid=$!
  }

  play_sox_linux()
  {
    stop_player
    play -q -- "$@" >/dev/null 2>&1 &
    tocai_player_pid=$!
  }

  stop_player()
  {
    kill -- $tocai_player_pid 2>/dev/null
  }

  local play_cmd
  if [[ $OSTYPE = msys ]]; then
    play_cmd=play_vlc_windows
  else
    play_cmd=play_sox_linux
  fi

  local valid_dirs=()

  local dir
  for dir in "$@"; do
    [ -d "$dir" ] && valid_dirs+=("$dir")
  done

  local dirs_with_albums="${valid_dirs[@]}"

  # TODO Filter
  # local dirs_with_albums=()
  # for dir in "$valid_dirs"; do
  #   $(ls "$dir"/*.{mp3} )

  while :; do

    local albums=()
    local index=1
    local album
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

    local option
    local files=()
    read -r -n 2 -p 'Choose album: ' option
    if ! [[ $option =~ ^[0-9][0-9]$ ]]; then
      printf " - invalid option\n\n"
    elif [ $option -eq 0 ]; then
      stop_player
      tocai_player_pid=
      printf " - stopping\n\n"
    elif [ $option -eq 99 ]; then
      stop_player
      printf " - exiting\n\n"
      return 2>/dev/null || exit
    elif [ $option -lt 0 ] || [ $option -ge $index ]; then
      printf " - non-existing album\n\n"
    else
      album="${albums[${option#0}]}"
      printf " - ok, let's play $album!\n\n"
      readarray -d $'\0' audio_files < <(find "$album" \( -name '*.mp3' -or -name '*.flac' \) -print0 | sort -nz)

      # audio_files=()

      # for file in "${all_files[@]}"; do
      #   soxi "$file" > /dev/null 2> /dev/null && audio_files+=("$file")
      # done

      # # TODO Fix
      # IFS=$'\n' sorted_files=($(sort -n <<<"${audio_files[@]}"))
      # unset IFS

      $play_cmd "${audio_files[@]}"
    fi
  done
)

tocai_main "$@"
