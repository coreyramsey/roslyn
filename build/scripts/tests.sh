#!/usr/bin/env bash
# Copyright (c) .NET Foundation and contributors. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

set -e
set -u

build_configuration=${1:-Debug}
runtime=${2:-dotnet}

this_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${this_dir}"/build-utils.sh

root_path="$(get_repo_dir)"
binaries_path="${root_path}"/Binaries
unittest_dir="${binaries_path}"/"${build_configuration}"/UnitTests
log_dir="${binaries_path}"/"${build_configuration}"/xUnitResults
nuget_dir="${HOME}"/.nuget/packages
xunit_console_version="$(get_package_version dotnet-xunit)"

if [[ "${runtime}" == "dotnet" ]]; then
    target_framework=netcoreapp2.0
    file_list=( "${unittest_dir}"/*/netcoreapp2.0/*.UnitTests.dll )
    xunit_console="${nuget_dir}"/xunit.runner.console/"${xunit_console_version}"/tools/${target_framework}/xunit.console.dll
elif [[ "${runtime}" == "mono" ]]; then
    file_list=(
        "${unittest_dir}/Microsoft.CodeAnalysis.CSharp.Symbol.UnitTests/net46/Microsoft.CodeAnalysis.CSharp.Symbol.UnitTests.dll"
        "${unittest_dir}/Microsoft.CodeAnalysis.CSharp.Syntax.UnitTests/net46/Microsoft.CodeAnalysis.CSharp.Syntax.UnitTests.dll"
        )
    xunit_console="${nuget_dir}"/xunit.runner.console/"${xunit_console_version}"/tools/net452/xunit.console.exe
else
    echo "Unknown runtime: ${runtime}"
    exit 1
fi

UNAME="$(uname)"
if [ "$UNAME" == "Darwin" ]; then
    runtime_id=osx-x64
elif [ "$UNAME" == "Linux" ]; then
    runtime_id=linux-x64
else
    echo "Unknown OS: $UNAME" 1>&2
    exit 1
fi

echo "Publishing ILAsm.csproj"
dotnet publish "${root_path}/src/Tools/ILAsm" --no-restore --runtime ${runtime_id} --self-contained -o "${binaries_path}/Tools/ILAsm"

echo "Using ${xunit_console}"

# Discover and run the tests
mkdir -p "${log_dir}"

exit_code=0
for file_name in "${file_list[@]}"
do
    log_file="${log_dir}"/"$(basename "${file_name%.*}.xml")"
    deps_json="${file_name%.*}".deps.json
    runtimeconfig_json="${file_name%.*}".runtimeconfig.json

    # If the user specifies a test on the command line, only run that one
    # "${3:-}" => take second arg, empty string if unset
    if [[ ("${3:-}" != "") && (! "${file_name}" =~ "${2:-}") ]]
    then
        echo "Skipping ${file_name}"
        continue
    fi

    echo Running "${runtime} ${file_name[@]}"
    if [[ "${runtime}" == "dotnet" ]]; then
        runner="dotnet exec --depsfile ${deps_json} --runtimeconfig ${runtimeconfig_json}"
        if [[ "${file_name[@]}" == *'Microsoft.CodeAnalysis.CSharp.Emit.UnitTests.dll' ]] || \
           [[ "${file_name[@]}" == *'Microsoft.CodeAnalysis.VisualBasic.Symbol.UnitTests.dll' ]] || \
           [[ "${file_name[@]}" == *'Microsoft.CodeAnalysis.CSharp.Semantic.UnitTests.dll' ]] || \
           [[ "${file_name[@]}" == *'Microsoft.CodeAnalysis.VisualBasic.Emit.UnitTests.dll' ]] || \
           [[ "${file_name[@]}" == *'Microsoft.CodeAnalysis.VisualBasic.Semantic.UnitTests.dll' ]] || \
           [[ "${file_name[@]}" == *'Roslyn.Compilers.VisualBasic.IOperation.UnitTests.dll' ]] 
        then
            echo "Skipping ${file_name[@]}"
            continue
        fi
    elif [[ "${runtime}" == "mono" ]]; then
        runner=mono
    fi
    if ${runner} "${xunit_console}" "${file_name[@]}" -xml "${log_file}"
    then
        echo "Assembly ${file_name[@]} passed"
    else
        echo "Assembly ${file_name[@]} failed"
        exit_code=1
    fi
done
exit ${exit_code}