public class MockHttpResponse implements HttpCalloutMock {
	private Boolean isSuccess;
	private String bodySuccess;
	private String bodyError;

	public MockHttpResponse(Boolean isSuccess, String bodySuccess, String bodyError){
		this.isSuccess = isSuccess;
		this.bodySuccess = bodySuccess;
		this.bodyError = bodyError;
	}

	// Implement this interface method
	public HTTPResponse respond(HTTPRequest request) {
		// Create a fake response
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');

		if (this.isSuccess) {
			response.setStatusCode(201);
			response.setStatus('success');
			response.setBody(this.bodySuccess);
		}
		else {
			response.setStatusCode(500);
			response.setStatus('error');
			response.setBody(this.bodyError);
		}

		return response;
	}
}
