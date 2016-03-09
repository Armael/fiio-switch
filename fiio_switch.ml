open Libudev
open ShcamlCommon

let fiio_sink = "alsa_output.usb-FiiO_DigiHug_USB_Audio-01.iec958-stereo"

let switch_sink sink =
  let run c = run c |> ignore in
  run @@ program "pactl" ["set-default-sink"; sink];
  run @@ begin
    program "pactl" ["list"; "short"; "sink-inputs"] -|
    Adaptor.Delim.fitting
      ~options:Delimited.{default_options with field_sep = '\t'} () -|
    cut (fun l -> (Line.Delim.fields l).(0)) -|
    sed (fun l ->
      run @@ program "pactl" ["move-sink-input"; Line.show l; sink];
      l)
  end

let _ =
  let ctx = Context.create () in

  let mon = Monitor.create ctx in
  Monitor.set_filter mon [Monitor.Subsystem_devtype ("input", None)];
  Monitor.start mon;

  while true do
    let d = Monitor.receive_device mon in
    match Device.sysattr d "name", Device.action d with
    | Some "FiiO DigiHug USB Audio", Some Device.Add ->
      print_endline ".";
      switch_sink fiio_sink
    | _ ->
      ()
  done
