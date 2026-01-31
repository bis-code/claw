// Story refinement - interactive editing of individual stories

import inquirer from 'inquirer';
import chalk from 'chalk';
import { ProposedStory } from './breakdown.js';

export type RefinementAction = 'accept' | 'modify' | 'split' | 'skip';

export interface RefinementResult {
  action: RefinementAction;
  stories: ProposedStory[];
}

export class StoryRefiner {
  /**
   * Refine a list of stories interactively
   */
  async refineStories(stories: ProposedStory[]): Promise<ProposedStory[]> {
    const refinedStories: ProposedStory[] = [];
    let storyIndex = 0;

    for (const story of stories) {
      storyIndex++;
      console.log(chalk.blue(`\n📋 Story ${storyIndex}/${stories.length}: "${story.title}"`));
      console.log(chalk.dim(`   Scope: ${story.scope.join(', ')}`));
      console.log(chalk.dim(`   Repos: ${story.repos.join(', ') || 'TBD'}`));
      console.log(chalk.dim(`   Est: ${story.estimatedHours}h`));
      if (story.dependsOn && story.dependsOn.length > 0) {
        console.log(chalk.dim(`   Depends on: ${story.dependsOn.join(', ')}`));
      }

      const result = await this.refineStory(story);

      if (result.action !== 'skip') {
        refinedStories.push(...result.stories);
      } else {
        console.log(chalk.yellow('   ⏭️  Skipped'));
      }
    }

    return refinedStories;
  }

  /**
   * Refine a single story
   */
  async refineStory(story: ProposedStory): Promise<RefinementResult> {
    const { action } = await inquirer.prompt([{
      type: 'list',
      name: 'action',
      message: 'Action:',
      choices: [
        { name: 'Accept as-is', value: 'accept' },
        { name: 'Modify scope', value: 'modify' },
        { name: 'Split into smaller stories', value: 'split' },
        { name: 'Skip this story', value: 'skip' },
      ],
    }]);

    switch (action) {
      case 'accept':
        return { action: 'accept', stories: [story] };

      case 'modify':
        const modified = await this.modifyStory(story);
        return { action: 'modify', stories: [modified] };

      case 'split':
        const splitStories = await this.splitStory(story);
        return { action: 'split', stories: splitStories };

      case 'skip':
        return { action: 'skip', stories: [] };

      default:
        return { action: 'accept', stories: [story] };
    }
  }

  /**
   * Modify story scope
   */
  private async modifyStory(story: ProposedStory): Promise<ProposedStory> {
    // Show current scope items with checkboxes
    const { selectedScope } = await inquirer.prompt([{
      type: 'checkbox',
      name: 'selectedScope',
      message: 'Select scope items to keep:',
      choices: story.scope.map(s => ({ name: s, checked: true })),
    }]);

    // Ask for additional scope items
    const { additionalScope } = await inquirer.prompt([{
      type: 'input',
      name: 'additionalScope',
      message: 'Add scope items (comma-separated, or empty):',
    }]);

    const newScope = [
      ...selectedScope,
      ...additionalScope.split(',').map((s: string) => s.trim()).filter(Boolean),
    ];

    // Ask for updated hours estimate
    const { hours } = await inquirer.prompt([{
      type: 'number',
      name: 'hours',
      message: 'Estimated hours:',
      default: story.estimatedHours,
    }]);

    console.log(chalk.green('   ✓ Story modified'));

    return {
      ...story,
      scope: newScope,
      estimatedHours: hours,
    };
  }

  /**
   * Split story into multiple smaller stories
   */
  private async splitStory(story: ProposedStory): Promise<ProposedStory[]> {
    const { splitCount } = await inquirer.prompt([{
      type: 'number',
      name: 'splitCount',
      message: 'How many stories to split into?',
      default: 2,
    }]);

    const stories: ProposedStory[] = [];

    for (let i = 1; i <= splitCount; i++) {
      console.log(chalk.dim(`\n   Split ${i}/${splitCount}:`));

      const { title } = await inquirer.prompt([{
        type: 'input',
        name: 'title',
        message: `Story ${i} title:`,
        default: `${story.title} (Part ${i})`,
      }]);

      const { scope } = await inquirer.prompt([{
        type: 'input',
        name: 'scope',
        message: `Story ${i} scope (comma-separated):`,
        default: story.scope[i - 1] || '',
      }]);

      const { hours } = await inquirer.prompt([{
        type: 'number',
        name: 'hours',
        message: `Story ${i} hours:`,
        default: Math.ceil(story.estimatedHours / splitCount),
      }]);

      stories.push({
        title,
        scope: scope.split(',').map((s: string) => s.trim()).filter(Boolean),
        repos: story.repos,
        estimatedHours: hours,
        dependsOn: i > 1 ? [stories[i - 2].title] : story.dependsOn,
      });
    }

    console.log(chalk.green(`   ✓ Split into ${splitCount} stories`));

    return stories;
  }

  /**
   * Quick refinement - just accept/skip without full interactive mode
   */
  async quickRefine(stories: ProposedStory[]): Promise<ProposedStory[]> {
    console.log(chalk.blue('\n📋 Stories to confirm:\n'));

    for (let i = 0; i < stories.length; i++) {
      const s = stories[i];
      console.log(`  ${i + 1}. ${s.title} (${s.estimatedHours}h)`);
    }

    const { confirm } = await inquirer.prompt([{
      type: 'confirm',
      name: 'confirm',
      message: 'Accept all stories?',
      default: true,
    }]);

    if (confirm) {
      return stories;
    }

    // Fall back to full refinement
    return this.refineStories(stories);
  }
}
