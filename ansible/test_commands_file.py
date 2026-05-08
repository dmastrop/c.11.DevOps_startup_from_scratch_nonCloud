import reprlib
print(reprlib.repr(commands))


commands = [
    # ORIGINAL — apt update without stream collapse
    "sudo DEBIAN_FRONTEND=noninteractive apt update -y",


    # ORIGINAL — apt install without stream collapse
    "sudo DEBIAN_FRONTEND=noninteractive apt install -y tomcat9",

    # Optional: apt update with collapsed streams (wrapped in bash)
    #"bash -c 'sudo DEBIAN_FRONTEND=noninteractive apt update -y 2>&1'",

    # Optional: apt install with collapsed streams (wrapped in bash)
    #"bash -c 'sudo DEBIAN_FRONTEND=noninteractive apt install -y tomcat9 2>&1'",


    # Optional: apt update with collapsed streams and write to file and then STDOUT
    #f"bash -c 'sudo DEBIAN_FRONTEND=noninteractive apt update -y > /tmp/apt_output_{thread_uuid}.txt 2>&1; cat /tmp/apt_output_{thread_uuid}.txt; rm /tmp/apt_output_{thread_uuid}.txt'",


    # Optional: apt install with collapsed streams and write to file and then STDOUT
    #f"bash -c 'sudo DEBIAN_FRONTEND=noninteractive apt install -y tomcat9 > /tmp/apt_output_{thread_uuid}.txt 2>&1; cat /tmp/apt_output_{thread_uuid}.txt; rm /tmp/apt_output_{thread_uuid}.txt'",




#### Failure commands for negative testing #####

    # Optional: simulate package failure. For apt commmands with collapsed streams this will result in a stub
    # "bash -c 'sudo DEBIAN_FRONTEND=noninteractive apt install -y tomcat99 2>&1'",

    # Optional: simulate runtime crash
    #"sudo nonexistent_binary --fail",

    # Optional: simulate chained failure with sleep
    # "sudo bash -c 'nonexistent_binary --fail; sleep 1'",

    # Optional: raw bash invocation
    #"bash -c 'nonexistent_binary'",




    # force a shell level failure. Not seeing STDOUT, STDERR and exit code is 0 verified with raw print of exit_code
    #"sudo bash -c 'echo test > /root/testfile'",

    # test out the strace on the echo test above. We are now getting exit_code=1 which is good but no logging
    #"strace -e write,execve -o /tmp/trace.log sudo bash -c 'echo test > /root/testfile' && cat /tmp/trace.log",

    # strace same as above but pipe all the strace error (-1) log lines to STDERR. The rest of the logic will take 
g   # care of tagging the registry_entry status for this.
    #"strace -e write,execve -o /tmp/trace.log sudo bash -c 'echo test > /root/testfile'; grep -E ' = -1 ' /tmp/trace.log >&2",

    # strace still no STDERR with above. Try this, writing directly to /dev/stderr
    #"strace -e write,execve -o /dev/stderr sudo bash -c 'echo test > /root/testfile'",

    # apply strace with this methodology.  Write the logs to /tmp/trace.log  
    # THIS IS WORKING with the added logic in install_tomcat to write the /tmp/trace.log to stderr. This throws nonzero exit
    # code and also injected stderr, so install_failed
    #"strace -e write,execve -o /tmp/trace.log sudo bash -c 'echo test > /root/testfile'",






    # touch: cannot touch '/root/testfile': Permission denied. This is not throwing any STDOUT or STDERR and exit_code is 0
    #"sudo touch /root/testfile",

    # apply strace to the command above
    # THIS IS WORKING. 
    #"strace -e write,execve -o /tmp/trace.log sudo touch /root/testfile",



    # bash: nonexistent_command: command not found
    #"bash -c \"nonexistent_command\"",

    # apply strace to the command above
    # THIS IS WORKING
    #"strace -e write,execve -o /tmp/trace.log bash -c \"nonexistent_command\"",





    # small script that exits with error and writes to STDERR
    #"bash -c \"echo -e '#!/bin/bash\\necho \\\"This is stderr\\\" >&2\\nexit 1' > /tmp/fail.sh && chmod +x /tmp/fail.sh && sudo /tmp/fail.sh\"",

    # apply strace to the command above
    # THIS IS WORKING
    #"strace -e write,execve -o /tmp/trace.log bash -c \"echo -e '#!/bin/bash\\necho \\\"This is stderr\\\" >&2\\nexit 1' > /tmp/fail.sh && chmod +x /tmp/fail.sh && sudo /tmp/fail.sh\"",




    ## Negative test D1 (exit_code forced to zero but non-whitelist stderr from strace to hit BLOCK3 install_failed code)
    # This one will produce exit_status of 0 but will have a non-whitelist in the stderr and so should be install_failed
    #"strace -e write,execve -o /tmp/trace.log bash -c \"echo 'error: something went wrong' >&2; exit 0\"",
    #"strace -e write,execve -o /tmp/trace.log bash -c \"python3 -c 'import sys; sys.stderr.write(\"error: something went wrong\\n\")'; exit 0\"",
    #"strace -e write,execve -o /tmp/trace.log bash -c \"python3 -c \\\"import sys; sys.stderr.write('error: something went wrong\\\\n')\\\"; exit 0\"",
    #"strace -e write,execve -o /tmp/trace.log bash -c \"python3 -c \\\"import os; os.write(2, b'error: something went wrong\\\\n')\\\"; exit 0\"",

    # THIS IS WORKING FOR THE test D1 negative test case:
    #"strace -f -e write,execve -o /tmp/trace.log bash -c \"python3 -c \\\"import os; os.write(2, b'error: something went wrong\\\\n')\\\"; exit 0\"",




    # E: Unable to locate package tomcat99 (BLOCK2 failure heuristic check install_failed)
    # THIS IS WORKING (but is stubbed; there is no error in stdout or stderr at all so this is the best we can do)
    #"sudo apt install tomcat99",



## More negative tests of new items added to the APT and strace whitelist

#### resume normal commands #####

    ## commands 3 and 4: 

    "sudo systemctl start tomcat9",

    # Optional: simulate a systemctl start failure. This is not a collapsed stream, should emit STDERR and should result in install_failed
    #"sudo systemctl start tomcat99",


    "sudo systemctl enable tomcat9"
]

