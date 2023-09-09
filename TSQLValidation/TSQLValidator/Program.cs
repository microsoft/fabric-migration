using System;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using TSQLValidator;
namespace TSQLValidator
{
    internal class Validate
    {
        private static IList<ParseError> errors;

        static void Main(string[] args)
        {
            try
            {
                var parser = new TSql150Parser(true, SqlEngineType.SqlAzure);
                string sql = File.ReadAllText(@"C:\Users\pvenkat\test_db_scripts\dbo\Stored Procedures\create_master_key_and_scoped_credential.sql");
                //Console.WriteLine(sql);
                //Console.WriteLine("==============================================================");
                string batchToprocess = string.Empty;
                
                using (StringReader sr = new StringReader(sql))
                {
                    TSqlFragment fragment = parser.Parse(sr, out errors);
                    IEnumerable<string> batches = GetBatches(fragment);

                    if(batches != null)
                        if (batches.Count() > 1)
                            batchToprocess = batches.ElementAt(1);
                        else
                            batchToprocess = batches.First();
                }

                using (StringReader sr = new StringReader(batchToprocess))
                {
                    TSqlFragment fragment = parser.Parse(sr, out errors);
                    var tokenStream = fragment.ScriptTokenStream;

                    foreach (var token in tokenStream)
                    {
                        if (token.TokenType == TSqlTokenType.SingleLineComment || token.TokenType == TSqlTokenType.MultilineComment)
                            token.Text = "";
                    }

                    Sql150ScriptGenerator generator = new Sql150ScriptGenerator();
                    generator.GenerateScript(fragment, out string script);

                    //File.WriteAllText(@"C:\Users\pvenkat\test_db_scripts\dbo\Stored Procedures\sample.sql", script);
                    Console.WriteLine(script);
                }



            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
        }

        private static IEnumerable<string> GetBatches(TSqlFragment fragment)
        {
            Sql150ScriptGenerator sg = new Sql150ScriptGenerator();
            TSqlScript script = fragment as TSqlScript;
            if (script != null)
            {
                foreach (var batch in script.Batches)
                {
                    yield return ScriptFragment(sg, batch);
                }
            }
            else
            {
                // TSqlFragment is a TSqlBatch or a TSqlStatement
                yield return ScriptFragment(sg, fragment);
            }
        }

        private static string ScriptFragment(SqlScriptGenerator sg, TSqlFragment fragment)
        {
            string resultString;
            sg.GenerateScript(fragment, out resultString);
            return resultString;
        }
    }
}