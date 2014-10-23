using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TechnicalExercise
{
    public class WordCounter : TechnicalExercise.IWordCounter
    {
        public WordCounter()
        {
        }

        private static string[] _defaultSeparators = { " ", ",", ".", "!", ":", ";", "-" };

        /// <summary>
        /// Collection of default word separators.
        /// </summary>
        public string[] DefaultSeparators
        {
            get { return _defaultSeparators; }
        }

        /// <summary>
        /// Method calculates how many times each word appears in the given sentence using default word separators.
        /// Word comparison is done as case-insensitive.
        /// </summary>
        /// <param name="sentence">Sentence from which words are calculated.</param>
        /// <returns>IDictionary with key as word and value as number of times the word appears in the sentence.</returns>
        public IDictionary<string, int> GetWordCount(string sentence)
        {
            return GetWordCount(sentence, _defaultSeparators);
        }

        /// <summary>
        /// Method calculates how many times each word appears in the given sentence.
        /// Word comparison is done as case-insensitive.
        /// </summary>
        /// <param name="sentence">Sentence from which words are calculated.</param>
        /// <param name="separators">Collection of strings used as word separators.</param>
        /// <returns>IDictionary with key as word and value as number of times the word appears in the sentence.</returns>
        public IDictionary<string, int> GetWordCount(string sentence, IEnumerable<string> separators)
        {
            ConcurrentDictionary<string, int> wordCount = new ConcurrentDictionary<string, int>();

            if (String.IsNullOrWhiteSpace(sentence))
                return wordCount;

            //get words in thesentence using given separators
            string[] words = sentence.ToLower().Split(separators.ToArray(), StringSplitOptions.RemoveEmptyEntries);

            //calculate how many times each word appears in words array
            Parallel.ForEach(words, word =>
                {
                    wordCount.AddOrUpdate(word, 1, (k, v) => ++v);
                });

            return wordCount;
        }
    }
}
