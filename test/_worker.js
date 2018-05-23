module.exports = (work) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      console.log(JSON.stringify(work))
      resolve()
    }, 200);
  })
}