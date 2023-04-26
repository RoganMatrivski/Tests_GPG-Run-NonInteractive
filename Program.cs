using System;
using System.IO;
using PgpCore;

class Program
{
    static async Task Main(string[] args)
    {
        if (args.Length != 3)
        {
            Console.WriteLine("Usage: <input-file> <key-file> <passphrase>");
            return;
        }

        string inputFilePath = args[0];
        string keyFilePath = args[1];
        string passphrase = args[2];

        FileInfo privateKey = new FileInfo(keyFilePath);
        EncryptionKeys encryptionKeys = new EncryptionKeys(privateKey, passphrase);

        // Reference input/output files
        FileInfo inputFile = new FileInfo(inputFilePath);

        // Decrypt
        PGP pgp = new PGP(encryptionKeys);
        using (FileStream inputFileStream = new FileStream(inputFilePath, FileMode.Open))
            // Decrypt to stdout
            await pgp.DecryptStreamAsync(inputFileStream, Console.OpenStandardOutput());
    }
}
