return {
    "mfussenegger/nvim-dap",
    dependencies = { "mfussenegger/nvim-dap-python" },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        require("dap-python").setup("/Users/leonardogavaudan/.virtualenvs/.virtualenvs/debugpy/bin/python")

        -- Start/continue debugging
        vim.keymap.set("n", "<Leader>os", function()
            dap.continue()
        end)

        -- Set breakpoint
        vim.keymap.set("n", "<Leader>b", function()
            dap.toggle_breakpoint()
        end)

        -- Step over the current line
        vim.keymap.set("n", "<Leader>j", function()
            dap.step_over()
        end)

        -- Step into the function
        vim.keymap.set("n", "<Leader>oi", function()
            dap.step_into()
        end)

        -- Step out of the current function
        vim.keymap.set("n", "<Leader>ou", function()
            dap.step_out()
        end)

        -- Stop the debugger (terminate session)
        vim.keymap.set("n", "<Leader>ot", function()
            dap.terminate()
        end)

        -- Toggle DAP UI (open/close debug windows)
        vim.keymap.set("n", "<Leader>od", function()
            dapui.toggle()
        end)

        -- Set conditional breakpoint (with expression)
        vim.keymap.set("n", "<Leader>oc", function()
            dap.set_breakpoint(vim.fn.input("Condition: "))
        end)

        -- Evaluate expression (hover on variable)
        vim.keymap.set("n", "<Leader>oe", function()
            dapui.eval()
        end)

        -- Open REPL (interactive debugger terminal)
        vim.keymap.set("n", "<Leader>or", function()
            dap.repl.open()
        end)

        -- Add Watchlist expression
        vim.keymap.set("n", "<Leader>ow", function()
            local widgets = require("dapui").elements.watches
            widgets.add(vim.fn.input("Watch expression: "))
        end)

        -- Open the Scopes panel (Locals is inside Scopes)
        vim.keymap.set("n", "<Leader>ofl", function()
            require("dapui").open({ "scopes" })
        end)

        -- Open the Breakpoints panel
        vim.keymap.set("n", "<Leader>ofb", function()
            require("dapui").open({ "breakpoints" })
        end)

        -- Open the Stacks panel
        vim.keymap.set("n", "<Leader>ofs", function()
            require("dapui").open({ "stacks" })
        end)

        -- Open the Watches panel
        vim.keymap.set("n", "<Leader>ofw", function()
            require("dapui").open({ "watches" })
        end)
    end,
}
