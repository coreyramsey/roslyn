﻿// Copyright (c) Microsoft.  All Rights Reserved.  Licensed under the Apache License, Version 2.0.  See License.txt in the project root for license information.

using System.Collections.Generic;
using Microsoft.CodeAnalysis.MSBuild.Logging;
using Roslyn.Utilities;

namespace Microsoft.CodeAnalysis.MSBuild
{
    /// <summary>
    /// Represents a project file loaded from disk.
    /// </summary>
    internal sealed class ProjectFileInfo
    {
        /// <summary>
        /// The path to the output file this project generates.
        /// </summary>
        public string OutputFilePath { get; }

        /// <summary>
        /// The command line args used to compile the project.
        /// </summary>
        public IReadOnlyList<string> CommandLineArgs { get; }

        /// <summary>
        /// The source documents.
        /// </summary>
        public IReadOnlyList<DocumentFileInfo> Documents { get; }

        /// <summary>
        /// The additional documents.
        /// </summary>
        public IReadOnlyList<DocumentFileInfo> AdditionalDocuments { get; }

        /// <summary>
        /// References to other projects.
        /// </summary>
        public IReadOnlyList<ProjectFileReference> ProjectReferences { get; }

        /// <summary>
        /// The error message produced when a failure occurred attempting to get the info. 
        /// If a failure occurred some or all of the information may be inaccurate or incomplete.
        /// </summary>
        public DiagnosticLog Log { get; }

        public ProjectFileInfo(
            string outputFilePath,
            IEnumerable<string> commandLineArgs,
            IEnumerable<DocumentFileInfo> documents,
            IEnumerable<DocumentFileInfo> additionalDocuments,
            IEnumerable<ProjectFileReference> projectReferences,
            DiagnosticLog log)
        {
            this.OutputFilePath = outputFilePath;
            this.CommandLineArgs = commandLineArgs.ToImmutableArrayOrEmpty();
            this.Documents = documents.ToImmutableReadOnlyListOrEmpty();
            this.AdditionalDocuments = additionalDocuments.ToImmutableArrayOrEmpty();
            this.ProjectReferences = projectReferences.ToImmutableReadOnlyListOrEmpty();
            this.Log = log;
        }

        public static ProjectFileInfo CreateEmpty(DiagnosticLog log)
            => new ProjectFileInfo(
                outputFilePath: null,
                commandLineArgs: SpecializedCollections.EmptyEnumerable<string>(),
                documents: SpecializedCollections.EmptyEnumerable<DocumentFileInfo>(),
                additionalDocuments: SpecializedCollections.EmptyEnumerable<DocumentFileInfo>(),
                projectReferences: SpecializedCollections.EmptyEnumerable<ProjectFileReference>(),
                log);
    }
}
