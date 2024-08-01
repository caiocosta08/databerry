const getS3RootDomain = () => {
  // if (process.env.NEXT_PUBLIC_AWS_ENDPOINT) {
  //   return `${process.env.NEXT_PUBLIC_AWS_ENDPOINT}`;
  // }
  const url = `https://cors.acutistecnologia.com/https://${process.env.NEXT_PUBLIC_S3_BUCKET_NAME}.s3.amazonaws.com`;
  console.log(url);
  // return `https://${process.env.NEXT_PUBLIC_S3_BUCKET_NAME}.s3.amazonaws.com`;
  return url;
};

export default getS3RootDomain;
