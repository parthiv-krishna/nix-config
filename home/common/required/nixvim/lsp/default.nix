{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;

  programs.nixvim.plugins.lsp = {
    enable = true;

    capabilities = ''
      capabilities = vim.lsp.protocol.make_client_capabilities()

      -- autocomplete capabilities
      capabilities.textDocument.completion.completionItem = {
        documentationFormat = { "markdown", "plaintext" },
        snippetSupport = true,
        preselectSupport = true,
        insertReplaceSupport = true,
        labelDetailsSupport = true,
        deprecatedSupport = true,
        commitCharactersSupport = true,
        tagSupport = { valueSet = { 1 } },
        resolveSupport = {
          properties = {
            "documentation",
            "detail",
            "additionalTextEdits",
          },
        },
      }

      -- semantic tokens
      capabilities.textDocument.semanticTokens = {
        multilineTokenSupport = true,
        overlappingTokenSupport = true,
        serverCancelSupport = true,
        augmentsSyntaxTokens = true,
      }

      -- code action support
      capabilities.textDocument.codeAction = {
        dynamicRegistration = false,
        codeActionLiteralSupport = {
          codeActionKind = {
            valueSet = {
              "",
              "quickfix",
              "refactor",
              "refactor.extract",
              "refactor.inline",
              "refactor.rewrite",
              "source",
              "source.organizeImports",
            },
          },
        },
        isPreferredSupport = true,
        disabledSupport = true,
        dataSupport = true,
        resolveSupport = {
          properties = { "edit" },
        },
      }
    '';

    inlayHints = true;

    keymaps = {
      silent = true;
      diagnostic = {
        "<leader>k" = "goto_prev";
        "<leader>j" = "goto_next";
        "<leader>e" = "open_float";
        "<leader>q" = "setloclist";
      };
      lspBuf = {
        "gd" = "definition";
        "gD" = "declaration";
        "gi" = "implementation";
        "gr" = "references";
        "gt" = "type_definition";
        "K" = "hover";
        "<leader>rn" = "rename";
        "<leader>ca" = "code_action";
        "<leader>f" = "format";
      };
    };

    # set up buffer-local keymaps and features
    onAttach = ''
      -- enable inlay hints if supported
      if client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end

      -- enable document highlight if supported
      if client.server_capabilities.documentHighlightProvider then
        vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
        vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "lsp_document_highlight" })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          group = "lsp_document_highlight",
          buffer = bufnr,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved" }, {
          group = "lsp_document_highlight",
          buffer = bufnr,
          callback = vim.lsp.buf.clear_references,
        })
      end
    '';
  };
}
