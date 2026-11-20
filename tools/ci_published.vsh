// Run the published-module checks with a per-job V module directory.
import opencltest
import os
import v.vmod

const release_source = 'https://github.com/antono2/v_opencl_bindings.git'
const strict_sources = ['test/main.c.v', 'examples/vector_add/main.v',
	'examples/getting_started/main.v', 'examples/algorithms/main.v', 'abi/main.c.v']
const strict_examples = ['test', 'examples/vector_add', 'examples/getting_started',
	'examples/algorithms']

fn required_env(name string) !string {
	value := os.getenv(name)
	if value == '' {
		return error('Set ${name} for this CI stage.')
	}
	return value
}

fn compatibility() ! {
	output := required_env('GITHUB_OUTPUT')!
	for script in ['scripts/compatibility.vsh', 'scripts/doctor.vsh'] {
		opencltest.compiler(@VEXE, ['run', script, '--self-test'])!
	}
	opencltest.compiler(@VEXE, ['run', 'scripts/compatibility.vsh', '--github-output', output])!
}

fn stage_root() !string {
	temporary := required_env('RUNNER_TEMP')!
	if !os.is_dir(temporary) {
		return error('RUNNER_TEMP must name an existing directory.')
	}
	stage := os.join_path(os.abs_path(temporary), 'opencl-published-ci')
	os.setenv('VMODULES', os.join_path(stage, 'modules'), true)
	return stage
}

fn assemble(stage string) !string {
	destination := os.join_path(stage, 'modules', 'antono2', 'opencl')
	os.mkdir_all(destination)!
	mut files := os.ls('.')!.filter(it.ends_with('.v') && os.is_file(it))
	files << ['v.mod', 'VERSION', 'LICENSE', 'GENERATOR_COMMIT', 'setup.vsh']
	for path in files {
		os.cp(path, os.join_path(destination, path))!
	}
	for directory in ['include', 'algorithms'] {
		os.cp_all(directory, os.join_path(destination, directory), true)!
	}
	return destination
}

fn abi(executable string, stage string, compiler string, extension string) ! {
	opencltest.compiler(executable, ['-cc', compiler, '-o',
		os.join_path(stage, 'opencl-abi-probe' + extension), 'abi/main.c.v'])!
	opencltest.compiler(executable, ['-cc', compiler, '-d', 'opencl_dynamic', '-o',
		os.join_path(stage, 'opencl-dynamic-probe' + extension), 'examples/getting_started'])!
}

fn release_tag() !string {
	version := os.read_file('VERSION')!.trim_space()
	parts := version.split('.')
	if parts.len != 3 || !parts.all(it.len > 0 && it.bytes().all(it.is_digit())) {
		return error('VERSION must contain a semantic version.')
	}
	if vmod.from_file('v.mod')!.version != version {
		return error('VERSION and v.mod disagree.')
	}
	tag := required_env('GITHUB_REF_NAME')!
	if tag != 'v' + version {
		return error('Expected release tag v${version}, got ${tag}.')
	}
	return tag
}

fn tag_commit(refs string, tag string) !string {
	direct_ref := 'refs/tags/' + tag
	peeled_ref := direct_ref + '^{}'
	mut direct := ''
	mut peeled := ''
	for line in refs.split_into_lines() {
		commit, name := line.split_once('\t') or { continue }
		if name == direct_ref {
			direct = commit
		} else if name == peeled_ref {
			peeled = commit
		}
	}
	if direct == '' {
		return error('Generator tag ${tag} was not found.')
	}
	return if peeled != '' { peeled } else { direct }
}

fn validate_release() !string {
	tag := release_tag()!
	expected := opencltest.pin('GENERATOR_COMMIT')!
	ref := 'refs/tags/' + tag
	refs :=
		opencltest.checked(['git', 'ls-remote', '--exit-code', release_source, ref, ref + '^{}'])!
	actual := tag_commit(refs, tag)!
	if actual != expected {
		return error('v_opencl_bindings ${tag} resolves to ${actual}, expected ${expected}.')
	}
	return tag
}

fn publish_release() ! {
	tag := validate_release()!
	if os.exec(['gh', 'release', 'view', tag]).exit_code != 0 {
		opencltest.checked(['gh', 'release', 'create', tag, '--verify-tag', '--generate-notes',
			'--title', 'opencl ' + tag])!
	}
}

fn run(args []string) ! {
	os.chdir(os.dir(@DIR))!
	os.unsetenv('VEXE')
	if args.len != 1 {
		return error('Expected one published OpenCL CI stage.')
	}
	match args[0] {
		'compatibility' {
			compatibility()!
			return
		}
		'publish-release' {
			publish_release()!
			return
		}
		'build-master' {
			opencltest.build_compiler('.ci-v-master', false)!
			return
		}
		'build-strict' {
			opencltest.build_compiler('.ci-v3', true)!
			return
		}
		'--self-test' {
			opencltest.self_test()!
			assert tag_commit('abc\trefs/tags/v1.0.0\n', 'v1.0.0')! == 'abc'
			assert tag_commit('abc\trefs/tags/v1.0.0\ndef\trefs/tags/v1.0.0^{}\n', 'v1.0.0')! == 'def'
			return
		}
		else {}
	}

	stage := stage_root()!
	module_path := assemble(stage)!
	match args[0] {
		'smoke' {
			opencltest.pin('GENERATOR_COMMIT')!
			opencltest.compiler(@VEXE, ['run', 'setup.vsh', '--check'])!
			opencltest.smoke(@VEXE, true, 'convenience_test.v')!
		}
		'particles' {
			opencltest.stage_dependencies(stage, true)!
			opencltest.particles(@VEXE, stage)!
		}
		'macos-abi' {
			opencltest.compiler(@VEXE, ['run', 'setup.vsh', '--check'])!
			abi(@VEXE, stage, 'clang', '')!
		}
		'windows-abi' {
			sdk := os.join_path(required_env('VCPKG_INSTALLATION_ROOT')!, 'installed',
				'x64-windows')
			os.setenv('OPENCL_SDK', sdk, true)
			opencltest.compiler(@VEXE, ['run', os.join_path(module_path, 'setup.vsh'),
				'--install'])!
			abi(@VEXE, stage, 'msvc', '.exe')!
		}
		'smoke-master' {
			opencltest.smoke(os.abs_path('.ci-v-master/v'), false, 'convenience_test.v')!
		}
		'strict-frontend' {
			for path in strict_sources {
				opencltest.compiler(os.abs_path('.ci-v3/v'), ['-new-compiler', '-check', path])!
			}
		}
		'strict-smoke' {
			for path in strict_examples {
				opencltest.compiler(os.abs_path('.ci-v3/v'), ['-new-compiler', '-n', '-cc', 'tcc',
					'run', path])!
			}
		}
		'dependency-master' {
			opencltest.stage_dependencies(stage, false)!
			opencltest.compiler(@VEXE, ['-cc', 'gcc', '-o', os.join_path(stage, 'vulkan-particles'),
				opencltest.particle_example])!
		}
		else {
			return error('Unknown published OpenCL CI stage: ${args[0]}')
		}
	}
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
