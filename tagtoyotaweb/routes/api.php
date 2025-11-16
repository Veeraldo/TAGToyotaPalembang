Route::get('/posts', function () {
    return \App\Models\Post::all();
});
