ffinput = get_input_files()
git_command = get_input("git_command")
custom_text = get_input("custom_text")
local user = users_find()[1]
get_token = shell_command("php occ user:setting " .. user["uuid"] .. " integration_github token")
if get_token["exit_code"] == 1 then
  add_message("Please make sure to configure authentication via the github integration\nNavigate to Personal Settings -> Connected Accounts and fill in the github integration configs.")
end
gitman = Nil
for i,dnode in ipairs(directory_listing(home())) do
  if dnode.name == ".gitmanager" then
    gitman = dnode
  end
end
if gitman == Nil then
  gitman = new_folder(home(), ".gitmanager")
end
git_tokenf = Nil
if directory_listing(gitman) == Nil then
  git_tokenf = new_file(gitman, "token.txt", get_token["output"])
else
  for i,dnode in ipairs(directory_listing(gitman)) do
    if dnode.name == "token.txt" then
      git_tokenf = dnode
    end
  end
end
if git_tokenf ~= Nil then
  if file_content(git_tokenf) ~= get_token["output"] then
    if file_delete(git_tokenf, false) then
      add_message("Deletion Succeeded")
    else
      add_message("Deletion Failed")
      if exists(git_tokenf) then
        add_message("Check log file for the reason")
      else
        add_message("Failed because file does not exist")
      end
    end
    git_tokenf = Nil
  end
end
if git_tokenf == Nil then
  git_tokenf = new_file(gitman, "token.txt", get_token["output"])
end

--git_auth = shell_command("gh auth login --with-token < " .. meta_data(git_tokenf)["local_path"])
--add_message("exit code: " .. git_auth["exit_code"])
help_output = {}
help_output["Create/Convert"] = "This command will attempt to git init using the name entered in the text field under the selected folder. If the text field is blank, it will attempt to use the selected folder as the repo."
help_output["Pull"] = "This command will attempt to pull the latest update for the selected repo folder or the repo specified."
help_output["Push"] = "This command will attempt to push the local changes to the remote repo for the selected repo folder or the repo specified."
help_output["Add"] = "This command will attempt to add the selected file(s) to a commit."
help_output["Commit"] = "This command will attempt to stage a commit to be pushed. Simple commit messages can be entered into the text field. If no text is entered it will use the file .git/COMMIT_EDITMSG."
help_output["Status"] = "Will show the working tree status, runs git status on the selected repo"
help_output["Log"] = "Show the commit logs for the selected repo."
help_output["Fetch"] = "Will attempt to fetch all if Dir selected or specific item if item selected or specified"
help_output["Remote"] = "Allows for interaction with the remote subcommand. Use the text field to form the command"
help_output["Revert"] = "Revert a commit specified by the entry in the text field"
help_output["Remove"] = "Remove selected file from the working tree and from the index. Does NOT delete the file."
help_output["Clone"] = "Clone the repo specified in the text field into the specified directory."
help_output["Rebase"] = "Reapply commits"
result = shell_command("git --help")
--help_output["Custom Git"] = "Extensibility to write custom commands for git\n" .. result["output"]
result = shell_command("gh --help")
--help_output["Custom GH"] = "Extensibility for the GH command\n" .. result["output"]

function is_repo(node)
  pnode = node
  while full_path(pnode) ~= full_path(home()) do
    add_message("pnode = " .. pnode.name)
    for i,dnode in ipairs(directory_listing(pnode)) do
      if dnode.name == ".git" and is_folder(dnode) then
        if pnode == node then
          add_message(".git folder exists in " .. node.name)
        else
          add_message("The folder " .. node.name .. " is part of the git repo " .. pnode.name .. " already")
        end
        return true
      end
    end
    pnode = get_parent(pnode)
  end
  return false
end

for i,node in ipairs(ffinput) do
  if git_command == "Create/Convert" then
    if is_folder(node) then
      if is_repo(node) then
        add_message("Cannot create/convert a folder that is already a repo or part of a repo")
      else
        add_message("Will attempt to convert " .. node.name .. " to a git repo")
      end
    else
      add_message(node.name .. " is not a folder")
    end
  elseif git_command == "Pull" then
    add_message("Will attempt to pull the latest update for " .. node.name)
  elseif git_command == "Push" then
    add_message("Will attempt to push committed changes for " .. node.name)
  elseif git_command == "Add" then
    add_message("Will attempt to add " .. node.name .. " to repo in " .. get_parent(node).name)
  elseif git_command == "Commit" then
    add_message("Will attempt to commit changes with message " .. custom_text .. " to repo in " .. node.name)
  elseif git_command == "Status" then
    add_message("Will attempt to get status info for repo in " .. node.name)
  elseif git_command == "Log" then
    add_message("Will attempt to get change log for repo in " .. node.name)
  elseif git_command == "Fetch" then
    add_message("Will attempt to fetch all if Dir selected or specific item if item selected or specified")
  elseif git_command == "Remote" then
    add_message("Will initiate a remote subcommand as specified " .. custom_text)
  elseif git_command == "Revert" then
    add_message("Will attempt to revert repo to specification")
  elseif git_command == "Remove" then
    add_message("Will remove the selected repo or file")
  elseif git_command == "Clone" then
    add_message("Will clone specified repo into " .. node.name)
  elseif git_command == "Rebase" then
    add_message("Will Rebase selected repo")
  elseif git_command == "Custom Git" then
    cmd = "git " .. custom_text
    result = shell_command(cmd)
    if result["error"] == Nil then
      result["error"] = "None"
    end
    add_message("Return Code: " .. result["exit_code"] .. "\n\nOutput: " .. result["output"] .. "\n\nError: " .. result["error"])
  elseif git_command == "Custom GH" then
    cmd = "gh " .. custom_text
    if custom_text == "auth login" then
      gitman = Nil
      for i,dnode in ipairs(directory_listing(home())) do
        if dnode.name == ".gitmanager" then
          gitman = dnode
        end
      end
      if gitman == Nil then
        gitman = new_folder(home(), ".gitmanager")
      end
      if directory_listing(gitman) == Nil then
        abort("Create a file named token.txt in /.gitmanager")
      else
        for i,dnode in ipairs(directory_listing(gitman)) do
          if dnode.name == "token.txt" then
            cmd = cmd .. "--with-token < " .. meta_data(dnode)["local_path"]
          end
        end
      end
    elseif string.find(custom_text, "auth login", 1, true) ~= Nil then
      abort("Do not attempt to log in with any additional parameters\nCreate a file /.gitmanager/token.txt and fill the contents with a token retrieved elsewhere\nUse 'gh auth login' to authenticate.\nUse 'gh auth token' to retrieve the token.")
    end
    add_message("String Find: " .. string.find(custom_text, "auth login", 1, true))
    result = shell_command(cmd)
    
  elseif git_command == "Help" then
    if not (custom_text == "") then
      if not (help_output[custom_text] == Nil) then
        add_message(custom_text .. " - " .. help_output[custom_text])
      else
        add_message(custom_text .. " is not a command")
      end
    else
      temp = Nil
      for i,dnode in ipairs(directory_listing(home(), "folder")) do
        if dnode.name == "Temp" then
          temp = dnode
        end
      end
      if temp == Nil then
        temp = new_folder(home(), "Temp")
      end
      for i,fnode in ipairs(directory_listing(temp),"file") do
        if fnode.name == "GitManagerHelp.txt" then
          file_delete(fnode)
        end
      end
      output = ""
      for_each(
        help_output,
        function (key, value)
          output = output .. "\n --- \n" .. key .. " - " .. value
        end
      )
      new_file(temp, "GitManagerHelp.txt", output)
      add_message("Open the file /Temp/GitManager.txt to view extended help for Git Manager")
    end
  end
end