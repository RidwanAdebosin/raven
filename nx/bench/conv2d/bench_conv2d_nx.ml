(** Benchmark suite for Nx 2D convolution operations *)

(** Configuration - common CNN layer sizes *)
let configs =
  [
    (* (batch, in_channels, out_channels, input_size, kernel_size) *)
    (1, 3, 32, 64, 3);
    (* Small: first conv layer, single image *)
    (8, 32, 64, 32, 3);
    (* Medium: mid-layer, small batch *)
    (16, 64, 128, 16, 3);
    (* Large: deep layer, larger batch *)
  ]

let backend_name = "Nx"

(** Helper to create benchmark name *)
let benchmark_name op_name batch in_ch out_ch img_size kernel_size dtype_label =
  Printf.sprintf "%s B%d C%d->%d %dx%d K%d %s (%s)" op_name batch in_ch out_ch
    img_size img_size kernel_size dtype_label backend_name

type conv_spec = {
  name : string;
  batch : int;
  in_channels : int;
  out_channels : int;
  img_size : int;
  kernel_size : int;
}
(** Conv2d operation specification *)

(** Create conv specs from configs *)
let conv_specs =
  List.map
    (fun (batch, in_ch, out_ch, img_size, kernel_size) ->
      {
        name = "Conv2d";
        batch;
        in_channels = in_ch;
        out_channels = out_ch;
        img_size;
        kernel_size;
      })
    configs

(** Setup tensors for Float32 *)
let setup_f32 spec =
  let input_shape =
    [| spec.batch; spec.in_channels; spec.img_size; spec.img_size |]
  in
  let kernel_shape =
    [|
      spec.out_channels; spec.in_channels; spec.kernel_size; spec.kernel_size;
    |]
  in
  let input = Nx.rand Nx.Float32 input_shape in
  let kernel = Nx.rand Nx.Float32 kernel_shape in
  (input, kernel)

(** Setup tensors for Float64 *)
let setup_f64 spec =
  let input_shape =
    [| spec.batch; spec.in_channels; spec.img_size; spec.img_size |]
  in
  let kernel_shape =
    [|
      spec.out_channels; spec.in_channels; spec.kernel_size; spec.kernel_size;
    |]
  in
  let input = Nx.rand Nx.Float64 input_shape in
  let kernel = Nx.rand Nx.Float64 kernel_shape in
  (input, kernel)

(** Build all benchmarks *)
let build_benchmarks () =
  let benchmarks = ref [] in

  (* Float32 benchmarks *)
  List.iter
    (fun spec ->
      let input, kernel = setup_f32 spec in
      let bench_name =
        benchmark_name spec.name spec.batch spec.in_channels spec.out_channels
          spec.img_size spec.kernel_size "f32"
      in
      let fn () = ignore (Nx.convolve2d input kernel) in
      benchmarks := Ubench.bench bench_name fn :: !benchmarks)
    conv_specs;

  (* Float64 benchmarks *)
  List.iter
    (fun spec ->
      let input, kernel = setup_f64 spec in
      let bench_name =
        benchmark_name spec.name spec.batch spec.in_channels spec.out_channels
          spec.img_size spec.kernel_size "f64"
      in
      let fn () = ignore (Nx.convolve2d input kernel) in
      benchmarks := Ubench.bench bench_name fn :: !benchmarks)
    conv_specs;

  List.rev !benchmarks

(** Default configuration *)
let default_config () =
  let open Ubench.Config in
  default |> time_limit 1.0 |> warmup 1 |> min_measurements 5
  |> geometric_scale 1.3 |> gc_stabilization false |> build

(** Main entry point *)
let () =
  let benchmarks = build_benchmarks () in
  let config = default_config () in
  ignore (Ubench.run ~config benchmarks)
