using System;
using System.Collections.Generic;

namespace TechnicalExercise
{
    public interface IWordCounter
    {
        string[] DefaultSeparators { get; }

        IDictionary<string, int> GetWordCount(string sentence);
        
        IDictionary<string, int> GetWordCount(string sentence, IEnumerable<string> separators);
    }
}
