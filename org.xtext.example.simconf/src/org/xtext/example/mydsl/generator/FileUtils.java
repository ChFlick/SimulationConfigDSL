package org.xtext.example.mydsl.generator;

import java.io.File;

public class FileUtils {
	public static void deleteDir(File dir) {
	    File[] files = dir.listFiles();
		if (files != null) {
			for (final File file : files) {
				deleteDir(file);
			}
		}
	    dir.delete();
	}
}
