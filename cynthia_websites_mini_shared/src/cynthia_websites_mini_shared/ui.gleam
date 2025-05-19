import bungibindies/bun/spawn
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import plinth/node/process
import simplifile

pub fn footer(can_hide: Bool, git_integration: Bool) {
  let z =
    "Made into this website with <a class='dark:text-sky-600 text-sky-800 underline' target='_blank' href='https://github.com/CynthiaWebsiteEngine/Mini'>Cynthia Mini</a>"
  let f = case git_integration {
    True ->
      [z]
      |> list.append(
        case { simplifile.is_directory(process.cwd() <> "/.git/") } {
          Ok(True) -> {
            [
              ", created from "
              <> case { todo } {
                Some(reponame) -> reponame
                None -> "a git repo"
              },
            ]
          }
          _ -> {
            []
          }
        },
      )
      |> string.concat
    False -> z
  }
  "<footer id='cynthiafooter' class='footer transition-all duration-[2s] ease-in-out footer-center bg-base-300 text-base-content p-1 h-fit fixed bottom-0'><aside><p>"
  <> f
  <> "</p></aside></footer>"
  <> case can_hide {
    True ->
      "
    <script defer>
	window.setTimeout(function () {
		console.log('now scroll.');
		window.addEventListener('scroll',
			function () {
				const classname = 'max-h-[5px]';
				document.querySelector('#cynthiafooter').style.height = '5px';
				document.querySelector('#cynthiafooter').addEventListener('click', function () {
					document.querySelector('#cynthiafooter').style.height = '';
				});
			},
			true,
		);
	}, 4000);
       </script>"
    False -> ""
  }
}

fn helper_get_git_remote() -> Option(String) {
  todo
}

/// The entire <body> of the 404 page.
pub fn notfoundbody() -> String {
  "<div class='absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit'>
	<div class='card bg-primary text-primary-content w-96'>
	  <div class='card-body items-center text-center'>
	    <h2 class='card-title'>404!</h2>
	    <p>Uh-oh, that page cannot be found.</p>
	    <div class='card-actions justify-end'>
	      <button class='btn btn-neutral-300' onclick='javascript:window.location.assign(\"/#/\");javascript:window.location.reload()'>Go home</button>
	      <button class='btn btn-ghost' onclick='javascript:window.history.back(1);javascript:window.location.reload()'>Go back</button>
	    </div>
	  </div>
	</div>
    </div>
    "
  <> footer(False, False)
}
