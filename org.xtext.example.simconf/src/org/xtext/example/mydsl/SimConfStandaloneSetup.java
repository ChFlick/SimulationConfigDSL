/*
 * generated by Xtext 2.23.0
 */
package org.xtext.example.mydsl;


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
public class SimConfStandaloneSetup extends SimConfStandaloneSetupGenerated {

	public static void doSetup() {
		new SimConfStandaloneSetup().createInjectorAndDoEMFRegistration();
	}
}
