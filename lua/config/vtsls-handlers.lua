local M = {}

-- Handler for the _typescript.moveToFileRefactoring command
-- This implements the client-side portion of the "Move to File" refactoring
-- as described in the vtsls documentation
M.handle_move_to_file = function(command, ctx)
	local action = command.arguments[1]
	local uri = command.arguments[2]
	local range = command.arguments[3]

	-- Use Telescope to select a target file
	local telescope = require("telescope.builtin")
	telescope.find_files({
		prompt_title = "Select target file for code move",
		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")

			-- Override the select action to handle the file selection
			actions.select_default:replace(function()
				local selection = require("telescope.actions.state").get_selected_entry()
				actions.close(prompt_bufnr)

				if not selection then
					vim.notify("Move to file cancelled", vim.log.levels.INFO)
					return
				end

				local target_file = selection.value

				-- Append the target file to the command arguments
				local modified_args = { action, uri, range, target_file }

				-- Execute the command with the modified arguments
				vim.lsp.buf_request(
					0, -- Use current buffer
					"workspace/executeCommand",
					{
						command = "_typescript.moveToFileRefactoring",
						arguments = modified_args,
					},
					function(err, result, _, _)
						if err then
							vim.notify("Error moving to file: " .. vim.inspect(err), vim.log.levels.ERROR)
							return
						end

						vim.notify("Successfully moved code to " .. target_file, vim.log.levels.INFO)

						-- Open the target file if it's not already open
						vim.cmd("edit " .. target_file)
					end
				)
			end)

			return true
		end,
	})
end

return M
