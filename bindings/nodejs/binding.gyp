{
  "targets": [
    {
      "target_name": "fastembed_native",
      "sources": [
        "addon/fastembed_napi.cc",
        "../shared/src/embedding_lib_c.c",
        "../shared/src/onnx_embedding_loader.c"
      ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")",
        "../shared/include",
        "../../bindings/onnxruntime/include"
      ],
      "defines": ["NAPI_DISABLE_CPP_EXCEPTIONS", "USE_ONNX_RUNTIME"],
      "conditions": [
        ["OS=='win'", {
          "defines": ["FASTEMBED_BUILDING_LIB"],
          "sources": [
            "../shared/src/embedding_lib.asm",
            "../shared/src/embedding_generator.asm"
          ],
              "libraries": [
                "<!@(node -p \"require('path').resolve(process.cwd(),'..','..','bindings','onnxruntime','lib','onnxruntime.lib').replace(/\\\\/g,'/')\")"
              ],
          "msvs_settings": {
            "VCCLCompilerTool": {
              "ExceptionHandling": 1,
              "AdditionalOptions": ["/std:c++17"]
            }
          },
          "rules": [
            {
              "rule_name": "asm_to_obj",
              "extension": "asm",
              "inputs": ["<(RULE_INPUT_PATH)"],
              "outputs": ["<(INTERMEDIATE_DIR)/<(RULE_INPUT_ROOT).obj"],
              "action": [
                "<(module_root_dir)/nasm_wrapper.bat",
            "-fwin64",
                "<(RULE_INPUT_PATH)",
                "-o",
                "<(INTERMEDIATE_DIR)/<(RULE_INPUT_ROOT).obj"
              ],
              "process_outputs_as_sources": 1,
              "message": "Assembling <(RULE_INPUT_PATH)"
            }
          ]
        }],
        ["OS=='linux'", {
          "sources": [
            "../shared/src/embedding_lib.asm",
            "../shared/src/embedding_generator.asm"
          ],
          "cflags": ["-fPIC"],
          "cflags_cc": ["-fPIC", "-std=c++17"],
          "libraries": ["-lm", "-L<(module_root_dir)/../../bindings/onnxruntime/lib", "-lonnxruntime"],
          "ldflags": ["-Wl,-rpath,<(module_root_dir)/../../bindings/onnxruntime/lib"],
          "rules": [
            {
              "rule_name": "asm_to_o",
              "extension": "asm",
              "inputs": ["<(RULE_INPUT_PATH)"],
              "outputs": ["<(INTERMEDIATE_DIR)/<(RULE_INPUT_ROOT).o"],
              "action": [
                "nasm",
                "-f",
                "elf64",
                "<(RULE_INPUT_PATH)",
                "-o",
                "<(INTERMEDIATE_DIR)/<(RULE_INPUT_ROOT).o"
              ],
              "process_outputs_as_sources": 1,
              "message": "Assembling <(RULE_INPUT_PATH)"
            }
          ]
        }],
        ["OS=='mac'", {
          "sources": [
            "../shared/src/embedding_lib.asm",
            "../shared/src/embedding_generator.asm"
          ],
          "cflags": ["-fPIC"],
          "cflags_cc": ["-fPIC", "-std=c++17"],
          "libraries": ["-lm", "-L<(module_root_dir)/../../bindings/onnxruntime/lib", "-lonnxruntime"],
          "ldflags": ["-Wl,-rpath,<(module_root_dir)/../../bindings/onnxruntime/lib"],
          "rules": [
            {
              "rule_name": "asm_to_o",
              "extension": "asm",
              "inputs": ["<(RULE_INPUT_PATH)"],
              "outputs": ["<(INTERMEDIATE_DIR)/<(RULE_INPUT_ROOT).o"],
              "action": [
                "nasm",
                "-f",
                "macho64",
                "<(RULE_INPUT_PATH)",
                "-o",
                "<(INTERMEDIATE_DIR)/<(RULE_INPUT_ROOT).o"
              ],
              "process_outputs_as_sources": 1,
              "message": "Assembling <(RULE_INPUT_PATH)"
            }
          ]
        }]
      ]
    }
  ]
}

