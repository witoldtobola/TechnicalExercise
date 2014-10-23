using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TechnicalExercise
{
    class Program
    {
        //private const string _defaultInput = "This is a statement, and so it this.";

        static void Main(string[] args)
        {
            Console.WriteLine("Write sentence: ");
            string sentence = Console.ReadLine();
            Console.WriteLine();

            Console.WriteLine("Number of words in the sentence:");

            //Create instance of WordCounter in the code for simplicity.
            //For more complicated scenarios that could be created using UnityContainer to make the code unit-testable by mocking that class.
            IWordCounter wordCounter = new WordCounter();

            //get number of words using default word separators
            IDictionary<string, int> wordCount = wordCounter.GetWordCount(sentence);

            //display results displaying words that occure most often first
            foreach (var word in wordCount.OrderByDescending(kvp => kvp.Value))
                Console.WriteLine(String.Format("{0} - {1}", word.Key, word.Value));

            Console.WriteLine();
            Console.WriteLine("Press any key...");
            Console.ReadKey();
        }
    }
}
