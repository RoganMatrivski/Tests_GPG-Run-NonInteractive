using CliWrap;
using CliWrap.Buffered;
using System;

class Program
{
    static async Task Main(string[] args)
    {
        if (args.Length < 2)
        {
            Console.WriteLine("Usage: dotnet run <passphrase> <encryptedPath>");
            return;
        }
        
        string passphrase = args[0];
        string encryptedPath = args[1];

        var result = await Cli.Wrap("gpg")
            .WithArguments(args => args
                .Add("--ignore-mdc-error")
                .Add("--pinentry-mode")
                .Add("loopback")
                .Add("--passphrase")
                .Add(passphrase)
                .Add("--yes")
                .Add("-d")
                .Add(encryptedPath))
            .ExecuteBufferedAsync();

        var StEx = result.StartTime + " - " + result.ExitTime;

        Console.WriteLine("StEx\n=============================");
        Console.WriteLine(StEx);
        Console.WriteLine("");

        if (result.ExitCode == 0)
        {
            string output = result.StandardOutput;
            // handle output
            Console.WriteLine("STDOUT\n=============================");
            Console.WriteLine(output);
        }
        else
        {
            string error = result.StandardError;
            // handle error
            Console.WriteLine("STDERR\n=============================");
            Console.WriteLine(error);
        }
    }
}
