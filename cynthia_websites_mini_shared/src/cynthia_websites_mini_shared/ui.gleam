pub const footer = "Made into this website with <a class='dark:text-sky-600 text-sky-800 underline' target='_blank' href='https://github.com/CynthiaWebsiteEngine/Mini'>Cynthia Mini</a>"

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
  <> footer
}
