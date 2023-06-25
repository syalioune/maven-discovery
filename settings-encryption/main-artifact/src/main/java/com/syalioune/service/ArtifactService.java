package com.syalioune.service;

public class ArtifactService {

    public void doSomething() {
        GcpService gcpService = new GcpService();
        gcpService.doSomething();
        GitlabService gitlabService = new GitlabService();
        gitlabService.doSomething();
        NexusService nexusService = new NexusService();
        nexusService.doSomething();
    }
}
