﻿/**
 * Copyright 2013-2013 Mohawk College of Applied Arts and Technology
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you 
 * may not use this file except in compliance with the License. You may 
 * obtain a copy of the License at 
 * 
 * http://www.apache.org/licenses/LICENSE-2.0 
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
 * License for the specific language governing permissions and limitations under 
 * the License.
 * 
 * User: fyfej
 * Date: 6-2-2013
 */
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using MohawkCollege.Util.Console.Parameters;
using System.ComponentModel;
using System.Collections.Specialized;

namespace MergeTool
{
    public class Parameters
    {

       
        /// <summary>
        /// Show help and exit
        /// </summary>
        [Parameter("help")]
        [Parameter("?")]
        [Description("Show help and exit")]
        public bool Help { get; set; }
        /// <summary>
        /// Merge two patient records together
        /// </summary>
        [Parameter("merge")]
        [Parameter("m")]
        [Description("Merge two or more patient records together")]
        public bool Merge { get; set; }
        /// <summary>
        /// List merge candidates
        /// </summary>
        [Parameter("list")]
        [Parameter("l")]
        [Description("List merge candidates")]
        public bool List { get; set; }
        /// <summary>
        /// Target of merge operation
        /// </summary>
        [Parameter("target")]
        [Parameter("t")]
        [Description("Target of merge operation")]
        public string Target { get; set; }
        /// <summary>
        /// The PIDs to merge
        /// </summary>
        [Parameter("*")]
        public StringCollection Pids { get; set; }

        /// <summary>
        /// Show detailed information
        /// </summary>
        [Description("Show detailed information for the listed persons")]
        [Parameter("info")]
        [Parameter("i")]
        public bool Info { get; set; }
    }
}
