﻿using System;
using System.IO;
using System.Linq;
using System.Reflection;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Repometric.Dockers.Generator
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var image = args[0];
            var linters = JObject.Parse(File.ReadAllText(@"config.json"));
            var defaultTemplate = @"default";

            var query = 
                from linter in linters["linters"]
                let name = (string)linter["name"]
                let platform = (string)linter["platform"]
                let docker = linters["dockers"][image][platform]
                let cmd = linters["platforms"][platform]
                let path = @"dockers/" + image + "/" + name + "/"
                let config = linter["config"]
                let templateFile = "templates/" + ReadConfig(config, "template", defaultTemplate)
                let template = File.ReadAllText(templateFile)
                let package = ReadConfig(config, "package", name)
                let run = cmd + " " + package
                let model = new { docker, name, cmd, run, path }
                let content = Format(template, model)
                select new { name, path, content };

            var list = query.ToList();
            foreach (var item in list)
            {
                Directory.CreateDirectory(item.path);
                File.WriteAllText(item.path + "Dockerfile", item.content);
                Console.WriteLine("Generate: " + item.name);
            }

            Console.WriteLine("Total: " + list.Count);
        }

        static string ReadConfig(JToken config, string name, string defaultValue)
        {
            return (string)(config != null && config[name] != null ? config[name] : defaultValue);
        }

        static string Format(string input, object p)
        {
            foreach (var prop in p.GetType().GetProperties())
            {
                input = input.Replace("{" + prop.Name + "}", (prop.GetValue(p) ?? "(null)").ToString());
            }
            return input;
        }
    }
}