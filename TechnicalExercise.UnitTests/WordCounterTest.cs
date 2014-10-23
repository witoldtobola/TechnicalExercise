using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Collections.Generic;
using System.Linq;

namespace TechnicalExercise.UnitTests
{
    [TestClass]
    public class WordCounterTest
    {
        [TestMethod]
        public void GetWordCount_EmptySentence_EmptyWordCountStructureReturned()
        {
            IWordCounter wordCounter = new WordCounter();
            IDictionary<string, int> wordCount = wordCounter.GetWordCount(String.Empty);
            Assert.AreEqual<int>(0, wordCount.Count);
        }

        [TestMethod]
        public void GetWordCount_OnlySeparatorsInSentence_EmptyWordCountStructureReturned()
        {
            IWordCounter wordCounter = new WordCounter();
            IDictionary<string, int> wordCount = wordCounter.GetWordCount("..,!");
            Assert.AreEqual<int>(0, wordCount.Count);
        }

        [TestMethod]
        public void GetWordCount_SampleSentence_WordCountStructureReturned()
        {
            IWordCounter wordCounter = new WordCounter();
            IDictionary<string, int> wordCount = wordCounter.GetWordCount("This is a statement, and so is this.");
            Assert.AreEqual<int>(6, wordCount.Count);
            Assert.AreEqual<int>(2, wordCount["this"]);
            Assert.AreEqual<int>(2, wordCount["is"]);
            Assert.AreEqual<int>(1, wordCount["a"]);
            Assert.AreEqual<int>(1, wordCount["statement"]);
            Assert.AreEqual<int>(1, wordCount["and"]);
            Assert.AreEqual<int>(1, wordCount["so"]);
        }

        [TestMethod]
        public void GetWordCount_CorrectSentenceAndDefaultSeperators_WordCountStructureReturned()
        {
            IWordCounter wordCounter = new WordCounter();
            IDictionary<string, int> wordCount = wordCounter.GetWordCount("Let's talk about differences between 32-bit systems and 64-bit systems.");
            Assert.AreEqual<int>(10, wordCount.Count);
            Assert.AreEqual<int>(2, wordCount["systems"]);
            Assert.AreEqual<int>(2, wordCount["bit"]);
            Assert.AreEqual<int>(1, wordCount["32"]);
            Assert.AreEqual<int>(1, wordCount["64"]);
            Assert.AreEqual<int>(1, wordCount["let's"]);
            Assert.AreEqual<int>(1, wordCount["talk"]);
            Assert.AreEqual<int>(1, wordCount["about"]);
            Assert.AreEqual<int>(1, wordCount["differences"]);
            Assert.AreEqual<int>(1, wordCount["between"]);
            Assert.AreEqual<int>(1, wordCount["and"]);
        }

        [TestMethod]
        public void GetWordCount_CorrectSentenceAndDashNotSeparator_WordCountStructureReturned()
        {
            IWordCounter wordCounter = new WordCounter();
            IDictionary<string, int> wordCount = wordCounter.GetWordCount("Let's talk about differences between 32-bit systems and 64-bit systems.",
                                                                            wordCounter.DefaultSeparators.Where(s => s != "-"));
            Assert.AreEqual<int>(9, wordCount.Count);
            Assert.AreEqual<int>(2, wordCount["systems"]);
            Assert.AreEqual<int>(1, wordCount["let's"]);
            Assert.AreEqual<int>(1, wordCount["32-bit"]);
            Assert.AreEqual<int>(1, wordCount["64-bit"]);
            Assert.AreEqual<int>(1, wordCount["talk"]);
            Assert.AreEqual<int>(1, wordCount["about"]);
            Assert.AreEqual<int>(1, wordCount["differences"]);
            Assert.AreEqual<int>(1, wordCount["between"]);
            Assert.AreEqual<int>(1, wordCount["and"]);
        }
        
    }
}
